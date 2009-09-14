-- exec pr_alert_replicationSynchronization 'mssql-ny', 'mssql_slv-ny', 'transactions_ap'
-- exec pr_alert_replicationSynchronization 'mssql-ny', 'mssql_slv-ny', 'transactions_hk'

ALTER procedure [dbo].[pr_alert_replicationSynchronization] (@cServerName_Publisher varchar(100), @cServerName_Subscriber varchar(100),
	@cDatabaseName varchar(100), @cTableName varchar(100) = 'transactions', @cDateField varchar(100) = 'dateCreated')
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
		select ''''publisher'''', convert(varchar(10), [' + @cDateField + '], 120), count(*), max([' + @cDateField + ']) as latestData
			from [' + @cDatabaseName + '].dbo.[' + @cTableName + '] (nolock)
			where [' + @cDateField + '] >= ''''' + convert(varchar(20), @dStartDate, 120) + '''''
				and [' + @cDateField + '] < ''''' + convert(varchar(20), @dEndDate, 120) + '''''
			group by convert(varchar(10), [' + @cDateField + '], 120)
			order by convert(varchar(10), [' + @cDateField + '], 120)'')
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
		select ''''subscriber'''', convert(varchar(10), [' + @cDateField + '], 120), count(*), max([' + @cDateField + ']) as latestData
			from [' + @cDatabaseName + '].dbo.[' + @cTableName + '] (nolock)
			where [' + @cDateField + '] >= ''''' + convert(varchar(20), @dStartDate, 120) + '''''
				and [' + @cDateField + '] < ''''' + convert(varchar(20), @dEndDate, 120) + '''''
			group by convert(varchar(10), [' + @cDateField + '], 120)
			order by convert(varchar(10), [' + @cDateField + '], 120)'')
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
			'as of ' + isnull(right(convert(varchar(10), b.latestData, 120), 5), 'NO DATA') + ' ' +
			'(' + convert(varchar(20), convert(decimal(10,2), convert(decimal(10,2), dateDiff(minute, b.latestData, getDate())) / 60.00)) + 'hrs).'
			as subject,
		'<b>Publisher [' + @cServerName_Publisher + '].[' + @cDatabaseName + ']</b> <br>' +
			'  Rows: ' + convert(varchar(20), a.numTransactions) + '<br>' +
			'  Data Timestamp: ' + convert(varchar(20), a.latestData, 120) + '<br><br>' +
		'<b>Subscriber [' + @cServerName_Subscriber + '].[' + @cDatabaseName + ']</b><br> ' +
			'  Rows: ' + isnull(convert(varchar(20), b.numTransactions), '0') + '<br>' +
			'  Data Timestamp: ' + isnull(convert(varchar(20), b.latestData, 120), '(No Data)'),
		1 as severity
		from ( select ymd, numTransactions, latestData from #results where location = 'publisher' ) a
		left outer join ( select ymd, numTransactions, latestData from #results where location = 'subscriber' ) b on a.ymd = b.ymd
		where abs(isnull(a.numTransactions, 0) - isnull(b.numTransactions, 0)) >= 15
			-- because of the ETL process, silence the alerts
			and not datePart(hour, getDate()) in (14, 15, 20, 21)
			and dateDiff(minute, b.latestData, getDate()) > 15
		order by a.ymd

	if exists (select [name] from mart.dbo.sysobjects where [name] = 'mart_replicationStatus')
	begin
		insert into mart.dbo.mart_replicationStatus (serverName, databaseName, tableName, numRecords, maxDate)
		select
			@cServerName_Publisher as serverName,
			@cDatabaseName as databaseName,
			@cTableName as tableName,
			numTransactions as numRows,
			latestData as maxDate
			from #results
			where location = 'publisher'

		insert into mart.dbo.mart_replicationStatus (serverName, databaseName, tableName, numRecords, maxDate)
		select
			@cServerName_Subscriber as serverName,
			@cDatabaseName as databaseName,
			@cTableName as tableName,
			numTransactions as numRows,
			latestData as maxDate
			from #results
			where location = 'subscriber'
	end

	drop table #results
end
GO
