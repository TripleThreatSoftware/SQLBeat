use [audit]
GO

-- exec pr_alert_objectChanges '2008-01-01', null
ALTER procedure [dbo].[pr_alert_objectChanges] (@dStartDate dateTime = null, @dEndDate dateTime = null)
as
begin
	set nocount on

--	declare @dStartDate dateTime
--	declare @dEndDate dateTime

	set @dStartdate = isnull(@dStartDate, dateAdd(hour, -28, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	select distinct serverName, databaseName
		into #currentDatabases
		from auditData_objectText
		where isCurrent = 1
			and ymd_lastSeen >= @dStartDate
			and ymd_lastSeen <= @dEndDate

	select distinct serverName, databaseName
		into #addedDatabases
		from auditData_objectText
		where isCurrent = 1
			and ymd_firstSeen >= @dStartDate
			and ymd_firstSeen <= @dEndDate

	select serverName, databaseName, max(ymd_lastSeen) as ymd_lastSeen
		into #droppedDatabases
		from auditData_objectText
		where isCurrent = 0
			and ymd_lastSeen >= @dStartDate
			and ymd_lastSeen <= @dEndDate
		group by serverName, databaseName

	delete #droppedDatabases
		from #droppedDatabases a
		join #currentDatabases b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

	-- dropped objects
	select *
		into #droppedObjects
		from auditData_objectText
		where isCurrent = 0
			and ymd_lastSeen >= @dStartDate
			and ymd_lastSeen <= @dEndDate

	-- added objects
	select *
		into #addedObjects
		from auditData_objectText
		where isCurrent = 1
			and ymd_firstSeen >= @dStartDate
			and ymd_firstSeen <= @dEndDate

	delete #droppedObjects
		from #droppedObjects a
		join #droppedDatabases b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

	delete #addedObjects
		from #addedObjects a
		join #addedDatabases b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

	create table #messages (ukey int identity, serverName varchar(200), subject varchar(500), message varchar(max))

	-- databases added
	insert into #messages (serverName, subject, message)
	select
		serverName,
		'Database [' + databaseName + '] was added.' as subject,
		'Database [' + databaseName + '] ' +
			'was added ' +
			'to ' + serverName + ' ' +
			'around ' + convert(varchar(20), getDate(), 120) + '.' as message
		from #addedDatabases
		group by serverName, databaseName

	-- databases dropped
	insert into #messages (serverName, subject, message)
	select
		serverName,
		'Database [' + databaseName + '] was dropped.' as subject,
		'Database [' + databaseName + '] ' +
			'was dropped ' +
			'from ' + serverName + ' ' +
			'around ' + convert(varchar(20), min(ymd_lastSeen), 120) + '.' as message
		from #droppedDatabases
		group by serverName, databaseName




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
	declare @nThisUkey bigint

	create table #then (codeLine varchar(8000), ukey int identity, isChanged bit default 0)
	create table #now (codeLine varchar(8000), ukey int identity, isChanged bit default 0)

	set @nThisUkey = 0

	while exists (
		select top 1 ukey
			from #addedObjects
			where ukey > @nThisUkey
		)
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
			@dYMD_then = ymd_lastSeen,
			@dYMD_now = ymd_firstSeen,
			@nCheckSumNow = isnull(checksum_now, 0),
			@nCheckSumThen = isnull(checksum_then, 0)
			from #addedObjects
			where ukey > @nThisUkey
			order by ukey

	--	print 'Processing [' + @cServerName + '].[' + @cDatabaseName + '].[' + @cObjectName + ']'

		-- only if they are not equal step through the text
		truncate table #then
		truncate table #now

--		print 'Changed: ' + @cObjectName + ' ' + convert(varchar(20), isnull(@nCheckSumThen, 0)) + '/' + convert(varchar(20), isnull(@nCheckSumNow, 0))

		-- if the object has some history
		if exists (select top 1 ukey from #droppedObjects where serverName = @cServerName and databaseName = @cDatabaseName and objectName = @cObjectName)
		begin

			set @nUkeyLine = 0

			while exists (
				select top 1 ukey
					from #droppedObjects
					where serverName = @cServerName
						and databaseName = @cDatabaseName
						and objectName = @cObjectName
						and ukey > @nUkeyLine
				)
			begin
				select top 1
					@nUkeyLine = ukey,
					@cThisLine = objectText
					from #droppedObjects
					where serverName = @cServerName
						and databaseName = @cDatabaseName
						and objectName = @cObjectName
						and ukey > @nUkeyLine
					order by ukey

				insert into #then (codeLine)
				select listItem
					from notification.dbo.fn_makeTableFromList(@cThisLine, char(13))
					where isnull(rtrim(ltrim(replace(replace(listItem, char(13), ''), char(10), ''))), '') <> ''

			end
		end

		-- we know this wasn't dropped, it was just changed
		delete from #droppedObjects where serverName = @cServerName and databaseName = @cDatabaseName and objectName = @cObjectName

		set @nUkeyLine = 0

		while exists (
			select top 1 ukey
				from #addedObjects
				where serverName = @cServerName
					and databaseName = @cDatabaseName
					and objectName = @cObjectName
					and ukey > @nUkeyLine
			)
		begin
			select top 1
				@nUkeyLine = ukey,
				@cThisLine = objectText
				from #addedObjects
				where serverName = @cServerName
					and databaseName = @cDatabaseName
					and objectName = @cObjectName
					and ukey > @nUkeyLine
				order by ukey

			insert into #now (codeLine)
			select listItem
				from notification.dbo.fn_makeTableFromList(@cThisLine, char(13))
				where isnull(rtrim(ltrim(replace(replace(listItem, char(13), ''), char(10), ''))), '') <> ''
		end

		set @cMessage = case
			when (select count(*) from #then) = 0
				then 'Object [' + isnull(@cDatabaseName, '') + '].[' + isnull(@cObjectName, '') + '] was added ' +
					'around ' + convert(varchar(20), isnull(@dYMD_now, ''), 120) + '.' + char(13) + char(13)
			else 'Object [' + isnull(@cDatabaseName, '') + '].[' + isnull(@cObjectName, '') + '] was changed ' +
					'between ' + convert(varchar(20), isnull(@dYMD_then, ''), 120) + ' ' +
					'and ' + convert(varchar(20), isnull(@dYMD_now, ''), 120) + '.' + char(13) + char(13) +
					'Old object text:' + char(13) + replicate('=', 40)
			end

		set @cSubject = 'Object [' + @cDatabaseName + '].[' + @cObjectName + '] was ' +
			case when (select count(*) from #then) = 0 then 'added'
				else 'changed'
				end + ' ' +
				'at ' + convert(varchar(20), isnull(@dYMD_now, getDate()), 120) + '.'

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

		if (select count(*) from #then) > 0
		begin
			select @cMessage = isnull(@cMessage, '') + char(13) +
				right('00000' + convert(varchar(5), isnull(ukey, 0)), 5) + ': ' +
				replace(replace(isnull(codeLine, ''), char(13), space(0)), char(10), space(0))
				from #then
				where isChanged = 1
		end

		if (select count(*) from #now) = 0
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

	-- so now, anything left in the #droppedObjects table really was dropped


	if @cMessage <> ''
		insert into #messages (serverName, [subject], [message])
		select serverName,
			'Object [' + isnull(databaseName, '') + '].[' + isnull(objectName, '') + '] was dropped ' +
				'around ' + convert(varchar(20), isnull(ymd_lastSeen, ''), 120) + '.' as subject,
			'Object [' + isnull(databaseName, '') + '].[' + isnull(objectName, '') + '] was dropped ' +
				'around ' + convert(varchar(20), isnull(ymd_lastSeen, ''), 120) + '.' as message
			from #droppedObjects

	-- if this is the first pass we've made against this server, don't send out any messages. it'll be all "object added"
	delete #messages
		from #messages a
		join (
			select serverName
				from auditData_objectText
				group by serverName
				having sum(case when isnull(ymd_firstSeen, '') <> isnull(ymd_lastSeen, '') then 1 else 0 end) = 0
			) b on a.serverName = b.serverName

	-- write the alerts
	insert into notification..notificationLog_stage (serverName, subject, message, severity)
	select serverName, subject, left(message, 4000), 2 as severity
		from #messages

	-- clean up
	drop table #droppedObjects
	drop table #addedObjects
	drop table #droppedDatabases
	drop table #addedDatabases
	drop table #currentDatabases

	drop table #then
	drop table #now
	drop table #messages
end
