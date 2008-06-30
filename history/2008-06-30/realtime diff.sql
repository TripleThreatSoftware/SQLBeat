----drop index auditData_objectText.ix_objectText_serverName_databaseName_objectName_auditRun
----go
--create clustered index ix_objectText_serverName_databaseName_objectName_auditRun on auditData_objectText (serverName, databaseName, objectName, ymd, ukey_auditRun) with fillfactor = 60
--go

--create index ix_objectText_serverName_auditRun on auditData_objectText (serverName, ukey_auditRun, ymd) with fillfactor = 60
--go

set nocount on

declare @dStartDate dateTime
declare @dEndDate dateTime
declare @nThisUkey bigint

set @dEndDate = '2008-06-30 09:30:00.000'

set @dEndDate = isnull(@dEndDate, getDate())

create table #messages (ukey int identity, serverName varchar(200), subject varchar(500), message varchar(max))

select
	a.serverName, a.databaseName, a.objectName,
	convert(int, 0) as ukey_then,
	convert(dateTime, '') as ymd_then,
	case when isnull(a.ukey_auditRun, 0) = isnull(b.ukey_auditRun, 0) then b.ukey_auditRun else null end as ukey_now,
	b.ymd as ymd_now,
	convert(bit, 0) as databaseDropped,
	convert(bit, 0) as databaseAdded,
	convert(bit, 0) as objectDropped,
	convert(bit, 0) as objectAdded,
	identity(int) as ukey
	into #results
	from (
		select serverName, max(ukey_auditRun) as ukey_auditRun, max(ymd) as ymd
			from auditData_objectText
			where ymd <= @dEndDate
				and ymd >= isnull(@dStartDate, dateAdd(week, -2, getDate()))
			group by serverName
		) b
	join (
		select serverName, databaseName, objectName, max(ukey_auditRun) as ukey_auditRun
			from auditData_objectText
			where ymd <= @dEndDate
				and ymd >= isnull(@dStartDate, dateAdd(week, -2, getDate()))
			group by serverName, databaseName, objectName
		) a on a.serverName = b.serverName
	order by a.serverName, a.databaseName, a.objectName


if @dStartDate is null
begin
	update #results
		set ukey_then = b.ukey_auditRun,
			ymd_then = b.ymd
		from #results a
		join (
			select
				a.serverName, a.databaseName, a.objectName,
				max(a.ukey_auditRun) as ukey_auditRun,
				max(a.ymd) as ymd
				from auditData_objectText a
				join #results b on a.serverName = b.serverName
					and a.databaseName = b.databaseName
					and a.objectName = b.objectName
					and (
						a.ukey_auditRun < b.ukey_now
						or isnull(b.ukey_now, 0) = 0
						)
				where a.ymd <= @dEndDate
					and a.ymd >= dateAdd(week, -2, getDate())
				group by a.serverName, a.databaseName, a.objectName
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName
				and a.objectName = b.objectName
end
else
begin
	update #results
		set ukey_then = b.ukey_auditRun,
			ymd_then = b.ymd
		from #results a
		join (
			select
				serverName, databaseName, objectName,
				min(ukey_auditRun) as ukey_auditRun,
				min(ymd) as ymd
				from auditData_objectText
				where ymd <= @dEndDate
					and ymd >= @dStartDate
				group by a.serverName, a.databaseName, a.objectName
			) b on a.serverName = b.serverName
				and a.databaseName = b.databaseName
				and a.objectName = b.objectName
end

update #results
	set databaseAdded = 1
	from #results a
	join (
		select serverName, databaseName
			from #results
			group by serverName, databaseName
			having sum(case when isnull(ukey_then, 0) <> 0 then 1 else 0 end) = 0
		) b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

if @@rowcount > 0
	insert into #messages (serverName, subject, message)
	select
		serverName,
		'Database [' + databaseName + '] was added.' as subject,
		'Database [' + databaseName + '] ' +
			'and ' + convert(varchar(20), count(*)) + ' objects were added ' +
			'to ' + serverName + ' ' +
			'around ' + convert(varchar(20), getDate(), 120) + '.' as message
		from #results
		where databaseAdded = 1
		group by serverName, databaseName

update #results
	set databaseDropped = 1
	from #results a
	join (
		select serverName, databaseName
			from #results
			group by serverName, databaseName
			having sum(case when isnull(ukey_now, 0) <> 0 then 1 else 0 end) = 0
		) b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

if @@rowcount > 0
	insert into #messages (serverName, subject, message)
	select
		serverName,
		'Database [' + databaseName + '] was dropped.' as subject,
		'Database [' + databaseName + '] ' +
			'and ' + convert(varchar(20), count(*)) + ' objects were dropped ' +
			'from ' + serverName + ' ' +
			'around ' + convert(varchar(20), min(ymd_then), 120) + '.' as message
		from #results
		where databaseDropped = 1
		group by serverName, databaseName

update #results
	set objectAdded = 1
	from #results a
	join (
		select serverName, databaseName, objectName
			from #results
			group by serverName, databaseName, objectName
			having sum(case when isnull(ukey_then, 0) <> 0 then 1 else 0 end) = 0
		) b on a.serverName = b.serverName
			and a.databaseName = b.databaseName
			and a.objectName = b.objectName

--if @@rowcount > 0
--	select distinct serverName, databaseName, objectName from #results where objectAdded = 1 and not databaseAdded = 1

update #results
	set objectDropped = 1
	from #results a
	join (
		select serverName, databaseName, objectName
			from #results
			group by serverName, databaseName, objectName
			having sum(case when isnull(ukey_now, 0) <> 0 then 1 else 0 end) = 0
		) b on a.serverName = b.serverName
			and a.databaseName = b.databaseName
			and a.objectName = b.objectName

--if @@rowcount > 0
--	select distinct serverName, databaseName, objectName from #results where objectDropped = 1 and not databaseDropped = 1

-- select * from #results order by serverName, databaseName, objectName

--delete from #results where objectName <> 'pr_cart_remove'
--select * from #results
--select * from auditData_objectText where ukey_auditRun in (122, 106) and objectName = 'pr_cart_remove'

declare @cServerName varchar(200)
declare @cDatabaseName varchar(500)
declare @cObjectName varchar(500)
declare @nCheckSumNow bigint
declare @nCheckSumThen bigint
declare @nUkeyAuditRun_then int
declare @nUkeyAuditRun_now int
declare @nUkeyLine bigint
declare @nUkeyNowLine bigint
declare @cThisLine varchar(max)
declare @bObjectAdded bit
declare @bObjectDropped bit
declare @cMessage varchar(max)
declare @cSubject varchar(500)
declare @dYMD_then dateTime
declare @dYMD_now dateTime

create table #then (codeLine varchar(8000), ukey int identity, isChanged bit default 0)
create table #now (codeLine varchar(8000), ukey int identity, isChanged bit default 0)

set @nThisUkey = 0

while exists (select top 1 ukey from #results where ukey > @nThisUkey and databaseDropped = 0 and databaseAdded = 0)
begin
	select top 1
		@nThisUkey = ukey,
		@cServerName = serverName,
		@cDatabaseName = databaseName,
		@cObjectName = objectName,
		@nUkeyAuditRun_then = ukey_then,
		@nUkeyAuditRun_now = ukey_now,
		@bObjectAdded = objectAdded,
		@bObjectDropped = objectDropped,
		@dYMD_then = ymd_then,
		@dYMD_now = ymd_now
		from #results
		where ukey > @nThisUkey
			and databaseDropped = 0
			and databaseAdded = 0
		order by ukey

--	print 'Processing [' + @cServerName + '].[' + @cDatabaseName + '].[' + @cObjectName + ']'

	if @bObjectAdded = 1 or @bObjectDropped = 1
	begin
		set @nCheckSumNow = 0
		set @nCheckSumThen = 1
	end
	else
	begin
--		print 'Now: ' + convert(varchar(20), isnull(@nUkeyAuditRun_now, 0))

		set @nCheckSumNow = 0
		set @nCheckSumNow = (
			select sum(notification.dbo.fn_checksum(isnull(objectText, '')) )
				from auditData_objectText
				where serverName = @cServerName
					and databaseName = @cDatabaseName
					and objectName = @cObjectName
					and ukey_auditRun = @nUkeyAuditRun_now
			)

--		print 'Then: ' + convert(varchar(20), isnull(@nUkeyAuditRun_then, 0))

		set @nCheckSumThen = 0
		set @nCheckSumThen = (
			select sum(notification.dbo.fn_checksum(isnull(objectText, '')))
				from auditData_objectText
				where serverName = @cServerName
					and databaseName = @cDatabaseName
					and objectName = @cObjectName
					and ukey_auditRun = @nUkeyAuditRun_then
			)
	end

	-- only if they are not equal step through the text
	if isnull(@nCheckSumThen, 0) <> isnull(@nCheckSumNow, 0)
	begin
		truncate table #then
		truncate table #now

--		print 'Changed: ' + @cObjectName + ' ' + convert(varchar(20), isnull(@nCheckSumThen, 0)) + '/' + convert(varchar(20), isnull(@nCheckSumNow, 0))

		if @bObjectAdded = 0
		begin

			set @nUkeyLine = 0

			while exists (
				select top 1 ukey
					from auditData_objectText
					where serverName = @cServerName
						and databaseName = @cDatabaseName
						and objectName = @cObjectName
						and ukey_auditRun = @nUkeyAuditRun_then
						and ukey > @nUkeyLine
				)
			begin
				select top 1
					@nUkeyLine = ukey,
					@cThisLine = objectText
					from auditData_objectText
					where serverName = @cServerName
						and databaseName = @cDatabaseName
						and objectName = @cObjectName
						and ukey_auditRun = @nUkeyAuditRun_then
						and ukey > @nUkeyLine
					order by ukey

				insert into #then (codeLine)
				select listItem
					from notification.dbo.fn_makeTableFromList(@cThisLine, char(13))
					where isnull(rtrim(ltrim(replace(replace(listItem, char(13), ''), char(10), ''))), '') <> ''

			end
		end

		if @bObjectDropped = 0
		begin

			set @nUkeyLine = 0

			while exists (
				select top 1 ukey
					from auditData_objectText
					where serverName = @cServerName
						and databaseName = @cDatabaseName
						and objectName = @cObjectName
						and ukey_auditRun = @nUkeyAuditRun_now
						and ukey > @nUkeyLine
				)
			begin
				select top 1
					@nUkeyLine = ukey,
					@cThisLine = objectText
					from auditData_objectText
					where serverName = @cServerName
						and databaseName = @cDatabaseName
						and objectName = @cObjectName
						and ukey_auditRun = @nUkeyAuditRun_now
						and ukey > @nUkeyLine
					order by ukey

				insert into #now (codeLine)
				select listItem
					from notification.dbo.fn_makeTableFromList(@cThisLine, char(13))
					where isnull(rtrim(ltrim(replace(replace(listItem, char(13), ''), char(10), ''))), '') <> ''
			end
		end

		set @cMessage = case
			when @bObjectAdded = 1
				then 'Object [' + isnull(@cDatabaseName, '') + '].[' + isnull(@cObjectName, '') + '] was added ' +
					'around ' + convert(varchar(20), isnull(@dYMD_now, ''), 120) + '.' + char(13) + char(13)
			when @bObjectDropped = 1
				then 'Object [' + isnull(@cDatabaseName, '') + '].[' + isnull(@cObjectName, '') + '] was dropped ' +
					'around ' + convert(varchar(20), isnull(@dYMD_now, ''), 120) + '.' + char(13) + char(13) +
					'Old object text:' + char(13) + replicate('=', 40)
			else 'Object [' + isnull(@cDatabaseName, '') + '].[' + isnull(@cObjectName, '') + '] was changed ' +
					'between ' + convert(varchar(20), isnull(@dYMD_then, ''), 120) + ' ' +
					'and ' + convert(varchar(20), isnull(@dYMD_now, ''), 120) + '.' + char(13) + char(13) +
					'Old object text:' + char(13) + replicate('=', 40)
			end

		set @cSubject = 'Object [' + @cDatabaseName + '].[' + @cObjectName + '] was ' +
			case when @bObjectAdded = 1 then 'added'
				when @bObjectDropped = 1 then 'dropped'
				else 'changed'
				end + '.'

		update #then
			set isChanged = 1
			from #then a
			left outer join #now b on notification.dbo.fn_removeFormatting(a.codeLine) = notification.dbo.fn_removeFormatting(b.codeLine)
				and a.ukey = b.ukey
			where b.ukey is null

		update #now
			set isChanged = 1
			from #now a
			left outer join #then b on notification.dbo.fn_removeFormatting(a.codeLine) = notification.dbo.fn_removeFormatting(b.codeLine)
				and a.ukey = b.ukey
			where b.ukey is null

		if isnull(@bObjectAdded, 0) = 0
		begin
			select @cMessage = isnull(@cMessage, '') + char(13) +
				right('00000' + convert(varchar(5), isnull(ukey, 0)), 5) + ': ' +
				replace(replace(isnull(codeLine, ''), char(13), space(0)), char(10), space(0))
				from #then
				where isChanged = 1
		end

		if isnull(@bObjectDropped, 0) = 0
		begin
			set @cMessage = @cMessage + char(13) + char(13) + 'New object text:' + char(13) + replicate('=', 40)

			select @cMessage = isnull(@cMessage, '') + char(13) +
				right('00000' + convert(varchar(5), isnull(ukey, 0)), 5) + ': ' +
				replace(replace(isnull(codeLine, ''), char(13), space(0)), char(10), space(0))
				from #now
				where isChanged = 1
		end

		if @cMessage <> ''
			insert into #messages (serverName, [subject], [message]) values (@cServerName, @cSubject, @cMessage)
	end

end

set @nThisUkey = 0

while exists (select top 1 ukey from #messages where ukey > @nThisUkey)
begin
	select top 1
		@nThisUkey = ukey,
		@cSubject = subject,
		@cMessage = message,
		@cServerName = serverName
		from #messages
		where ukey > @nThisUkey
		order by ukey

	exec notification.dbo.pr_sendMessage @cFrom='heybear@gmail.com', @cTo='cole@sqlbeat.com', @cSubject=@cSubject, @cBody=@cMessage
end

go

drop table #then
drop table #now
drop table #results
drop table #messages
