-- exec pr_alert_replicationSynchronization 'mssql-ny', 'mssql_slv-ny', 'transactions_ap'
-- exec pr_alert_replicationSynchronization 'mssql-ny', 'mssql_slv-ny', 'transactions_hk'

CREATE procedure [pr_alert_replicationSynchronization] (@cServerName_Publisher varchar(100), @cServerName_Subscriber varchar(100), @cDatabaseName varchar(100))
as
begin

	-- declare @cServerName_Publisher varchar(100)
	-- declare @cServerName_Subscriber varchar(100)
	-- declare @cDatabaseName varchar(100)
	--
	-- set @cServerName_Publisher = 'mssql-ny'
	-- set @cServerName_Subscriber = 'mssql_slv-ny'
	-- set @cDatabaseName = 'transactions_ap'

	declare @dMaxDate dateTime

	set @dMaxDate = dateAdd(minute, -5, getDate())

	declare @dStartDate dateTime
	declare @dEndDate dateTime
	declare @cSQLString nvarchar(4000)

	set @dStartDate = dateAdd(day, -2, convert(varchar(10), @dMaxDate, 120))
	set @dEndDate = @dMaxDate

	create table #results (location varchar(100), ymd dateTime, numTransactions bigint, latestData dateTime)

	if exists (select [name] from sysobjects where [name] = 'pr_checkTransactionCount_temp')
		drop procedure pr_checkTransactionCount_temp

	set @cSQLString = '
	create procedure pr_checkTransactionCount_temp
	as
	begin
		select *
			from openQuery([' + @cServerName_Publisher + '], ''
		select ''''publisher'''', convert(varchar(10), DateCreated, 120), count(*), max(dateCreated) as latestData
			from [' + @cDatabaseName + '].dbo.transactions (nolock)
			where DateCreated >= ''''' + convert(varchar(20), @dStartDate, 120) + '''''
				and DateCreated < ''''' + convert(varchar(20), @dEndDate, 120) + '''''
			group by convert(varchar(10), DateCreated, 120)
			order by convert(varchar(10), DateCreated, 120)'')
	end'

	exec sp_executeSQL @cSQLString

	insert into #results
	exec pr_checkTransactionCount_temp

	--**************************
	-- Now, check the subscriber

	if exists (select [name] from sysobjects where [name] = 'pr_checkTransactionCount_temp')
		drop procedure pr_checkTransactionCount_temp

	set @cSQLString = '
	create procedure pr_checkTransactionCount_temp
	as
	begin
		select *
			from openQuery([' + @cServerName_Subscriber + '], ''
		select ''''subscriber'''', convert(varchar(10), DateCreated, 120), count(*), max(dateCreated) as latestData
			from [' + @cDatabaseName + '].dbo.transactions (nolock)
			where DateCreated >= ''''' + convert(varchar(20), @dStartDate, 120) + '''''
				and DateCreated < ''''' + convert(varchar(20), @dEndDate, 120) + '''''
			group by convert(varchar(10), DateCreated, 120)
			order by convert(varchar(10), DateCreated, 120)'')
	end'

	exec sp_executeSQL @cSQLString

	insert into #results
	exec pr_checkTransactionCount_temp

	if exists (select [name] from sysobjects where [name] = 'pr_checkTransactionCount_temp')
		drop procedure pr_checkTransactionCount_temp

	-- select a.ymd,
	-- 	a.numTransactions as numTransactions_source, b.numTransactions as numTransactions_destination,
	-- 	a.latestData as latestData_source, b.latestData as latestData_destination
	-- 	from ( select ymd, numTransactions, latestData from #results where location = 'publisher' ) a
	-- 	left outer join ( select ymd, numTransactions, latestData from #results where location = 'subscriber' ) b on a.ymd = b.ymd
	--	where isnull(a.numTransactions, 0) <> isnull(b.numTransactions, 0)
	-- 	order by a.ymd

	insert into notification..notificationLog_stage (serverName, subject, message, severity)
	select @cServerName_Subscriber as serverName,
		'Subscription [' + @cDatabaseName + '] is out of synch ' +
			'for ' + convert(varchar(10), a.ymd, 120) +
			isnull(' (' + convert(varchar(20), dateDiff(hour, b.latestData, a.latestData)) + ' hrs)', '') + '.' as subject,
		'Publisher [' + @cServerName_Publisher + '].[' + @cDatabaseName + '] ' +
			'shows ' + convert(varchar(20), a.numTransactions) + ' rows ' +
			'as of ' + convert(varchar(20), a.latestData, 120) + ', ' +
			'while the subscriber [' + @cServerName_Subscriber + '].[' + @cDatabaseName + '] ' +
			'shows ' + isnull(convert(varchar(20), b.numTransactions), '0') + ' rows ' +
			'as of ' + isnull(convert(varchar(20), b.latestData, 120), '(No Data)') + '. ',
		1 as severity
		from ( select ymd, numTransactions, latestData from #results where location = 'publisher' ) a
		left outer join ( select ymd, numTransactions, latestData from #results where location = 'subscriber' ) b on a.ymd = b.ymd
		where isnull(a.numTransactions, 0) <> isnull(b.numTransactions, 0)
		order by a.ymd

	drop table #results
end



GO
