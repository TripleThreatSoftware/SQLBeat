USE [Audit]
GO
/****** Object:  StoredProcedure [dbo].[pr_alert_objectChanges]    Script Date: 2/13/2017 11:21:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- select * from notification..notificationLog_stage
-- select top 100 * from notification..notificationLog order by ukey desc
-- exec pr_alert_objectChanges '2009-09-15 00:00:00.000', '2008-09-16 10:00:00.000'
ALTER procedure [dbo].[pr_alert_objectChanges] (@dStartDate dateTime = null, @dEndDate dateTime = null)
as
begin
	set nocount on

	--declare @dStartDate dateTime
	--declare @dEndDate dateTime

	declare @dChange dateTime

	set @dStartdate = isnull(@dStartDate, dateAdd(day, -7, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	select distinct serverName, databaseName
		into #currentDatabases
		from auditData_objectText (nolock)
		where isCurrent = 1
			--and ymd_lastSeen >= @dStartDate
			--and ymd_lastSeen <= @dEndDate

	select
		serverName, databaseName, min(ymd_firstSeen) as ymd_firstSeen, count(distinct objectname) as numObjects
		into #addedDatabases
		from auditData_objectText (nolock)
		where isCurrent = 1
		group by serverName, databaseName
		having min(ymd_firstSeen) = max(ymd_firstSeen)
			and min(ymd_firstSeen) >= @dStartDate
			and min(ymd_firstSeen) <= @dEndDate

	-- if there are more than 200 objects changed, consider it "added"
	insert into #addedDatabases (serverName, databaseName, ymd_firstSeen, numObjects)
	select a.*
		from (
			select
				serverName, databaseName, min(ymd_firstSeen) as ymd_firstSeen, count(distinct objectname) as numObjects
				from auditData_objectText (nolock)
				where isCurrent = 1
					and ymd_firstSeen between @dStartDate and @dEndDate
					and objectName not like 'df%'
				group by serverName, databaseName
				having count(distinct objectname) > 200
			) a
		left outer join #addedDatabases b on a.serverName = b.serverName
			and a.databaseName = b.databaseName
		where b.serverName is null

	select serverName, databaseName, max(ymd_lastSeen) as ymd_lastSeen
		into #droppedDatabases
		from auditData_objectText (nolock)
		where isCurrent = 0
			and ymd_lastSeen >= @dStartDate
			and ymd_lastSeen <= @dEndDate
		group by serverName, databaseName

	delete #droppedDatabases
		from #droppedDatabases a
		join #currentDatabases b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

	--delete #droppedDatabases
	--	from #droppedDatabases a
	--	where databasename in ('AppDb_a', 'AppDb_b', 'AppDb_sourcedata_a', 'AppDb_sourcedata_b')

	--if suser_sname() = 'admin'
	--begin
	--	select * from #currentDatabases where servername = 'web06' order by servername, databasename
	--	select * from #droppedDatabases where servername = 'web06' order by servername, databasename
	--end

	-- dropped objects
	-- drop table #droppedObjects
	select *, convert(int, null) as id_newObject
		into #droppedObjects
		from auditData_objectText (nolock)
		where isCurrent = 0
			and ymd_lastSeen >= @dStartDate
			and ymd_lastSeen <= @dEndDate
			and objectName not like 'df%'

	update #droppedObjects
		set id_newObject = b.id
		from #droppedObjects a
		join auditData_objectText b on a.servername = b.servername
			and a.databasename = b.databasename
			and a.objectname = b.objectname
			and a.xtype = b.xtype
			and b.isCurrent = 1

	-- added objects
	select *
		into #addedObjects
		from auditData_objectText (nolock)
		where isCurrent = 1
			and ymd_firstSeen >= @dStartDate
			and ymd_firstSeen <= @dEndDate
			and objectName not like 'df%'

	-- select top 100 * from #addedObjects
	set identity_insert #addedObjects on
	insert into #addedObjects (ukey, servername, databasename, objectname, id, xtype, objecttext, textchecksum, ymd_firstseen, ymd_lastseen, iscurrent, colid)
	select a.ukey, a.servername, a.databasename, a.objectname, a.id, a.xtype, a.objecttext, a.textchecksum, a.ymd_firstseen, a.ymd_lastseen, a.iscurrent, a.colid
		from auditData_objectText a (nolock)
		join (
			select distinct a.servername, a.databasename, a.objectname, a.xtype, a.id_newobject, a.colid
				from #droppedObjects a
				left outer join #addedObjects b on a.servername = b.servername
					and a.databasename = b.databasename
					and a.objectname = b.objectname
					and a.xtype = b.xtype
				where id_newobject is not null
					and b.id is null
			) b on a.servername = b.servername
			and a.databasename = b.databasename
			and a.objectname = b.objectname
			and a.xtype = b.xtype
			and a.colid = b.colid
			and a.id = b.id_newObject
		where a.isCurrent = 1

	set identity_insert #addedObjects off

	delete #droppedObjects
		from #droppedObjects a
		join #droppedDatabases b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

	delete #droppedObjects
		from #droppedObjects a
		join #addedDatabases b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

	delete #addedObjects
		from #addedObjects a
		join #addedDatabases b on a.serverName = b.serverName
			and a.databaseName = b.databaseName

	create table #messages (ukey int identity, serverName varchar(200), subject varchar(500), message varchar(max), ymd dateTime default getDate(), databaseName varchar(200), objectName varchar(200), objectType varchar(200))

	-- databases added
	insert into #messages (serverName, subject, message, ymd, databaseName)
	select
		serverName,
		'Database [' + databaseName + '] was added.' as subject,
		'Database [' + databaseName + '], with ' + convert(varchar(20), numObjects) + ' objects, ' +
			'was added ' +
			'to ' + serverName + ' ' +
			'around ' + convert(varchar(20), ymd_firstSeen, 120) + '.' as message,
		ymd_firstSeen, databaseName
		from #addedDatabases
		where not databasename in ('AppDb_a', 'AppDb_b', 'AppDb_sourcedata_a', 'AppDb_sourcedata_b')

	-- databases dropped
	insert into #messages (serverName, subject, message, ymd, databaseName)
	select
		serverName,
		'Database [' + databaseName + '] was dropped.' as subject,
		'Database [' + databaseName + '] ' +
			'was dropped ' +
			'from ' + serverName + ' ' +
			'around ' + convert(varchar(20), min(ymd_lastSeen), 120) + '.' as message,
		min(ymd_lastSeen), databaseName
		from #droppedDatabases
		where not databasename in ('AppDb_a', 'AppDb_b', 'AppDb_sourcedata_a', 'AppDb_sourcedata_b')
		group by serverName, databaseName


	--select * from #addedObjects  where id = 64794688 and servername = 'etl01.office' order by serverName, databaseName, objectName
	--select * from #droppedObjects  where id = 64794688 and servername = 'etl01.office' order by serverName, databaseName, objectName

	--select * from auditData_objectText where id = 64794688 and servername = 'etl01.office'

	declare @cServerName varchar(200)
	declare @cDatabaseName varchar(500)
	declare @cObjectName varchar(500)
	declare @nUkeyLine bigint
	declare @nUkeyNowLine bigint
	declare @cThisLine varchar(max)
	declare @cMessage varchar(max)
	declare @cSubject varchar(500)
	declare @cObjectType varchar(100)
	declare @dYMD_then dateTime
	declare @dYMD_now dateTime
	declare @nThisUkey bigint
	declare @bIsChanged bit
	declare @nThisLineNumber int
	declare @nLastLineNumber int
	declare @cCarryOver varchar(8000)

	create table #then (codeLine varchar(8000), ukey int identity, isChanged bit default 0)
	create table #now (codeLine varchar(8000), ukey int identity, isChanged bit default 0)

	set @nThisUkey = 0

	while exists (
		select top 1 ukey
			from #addedObjects
			where ukey > @nThisUkey
		)
	begin
		set @dChange = ''

		select top 1
			@nThisUkey = ukey,
			@cServerName = serverName,
			@cDatabaseName = databaseName,
			@cObjectName = objectName,
			@cObjectType = xtype,
			@dYMD_then = ymd_lastSeen,
			@dYMD_now = ymd_firstSeen
			from #addedObjects
			where ukey > @nThisUkey
			order by ukey

	--	print 'Processing [' + @cServerName + '].[' + @cDatabaseName + '].[' + @cObjectName + ']'

		-- only if they are not equal step through the text
		truncate table #then
		truncate table #now

--		print 'Changed: ' + @cObjectName + ' ' + convert(varchar(20), isnull(@nCheckSumThen, 0)) + '/' + convert(varchar(20), isnull(@nCheckSumNow, 0))

		set @cCarryOver = ''

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
					@cThisLine = objectText,
					@dYMD_then = ymd_lastSeen
					from #droppedObjects
					where serverName = @cServerName
						and databaseName = @cDatabaseName
						and objectName = @cObjectName
						and ukey > @nUkeyLine
					order by ukey

				set @cThisLine = @cCarryOver + @cThisLine
				set @cCarryOver = ''

				if right(@cThisLine, 1) <> char(13)
					and (charindex(char(13), reverse(@cThisLine)) - 1) > 0
					and len(@cThisLine) - charindex(char(13), reverse(@cThisLine)) > 0
				begin
					set @cCarryOver = reverse(substring(reverse(@cThisLine), 1, charindex(char(13), reverse(@cThisLine)) - 1))
					set @cThisLine = left(@cThisLine, len(@cThisLine) - charindex(char(13), reverse(@cThisLine)))
				end

				insert into #then (codeLine)
				select listItem
					from notification.dbo.fn_makeTableFromList(@cThisLine, char(13))
					where isnull(rtrim(ltrim(replace(replace(listItem, char(13), ''), char(10), ''))), '') <> ''

			end
		end

		-- we know this wasn't dropped, it was just changed
--		delete from #droppedObjects where serverName = @cServerName and databaseName = @cDatabaseName and objectName = @cObjectName

		set @nUkeyLine = 0
		set @cCarryOver = ''

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

			set @cThisLine = @cCarryOver + @cThisLine
			set @cCarryOver = ''

			if right(@cThisLine, 1) <> char(13)
				and (charindex(char(13), reverse(@cThisLine)) - 1) > 0
				and len(@cThisLine) - charindex(char(13), reverse(@cThisLine)) > 0
			begin
				set @cCarryOver = reverse(substring(reverse(@cThisLine), 1, charindex(char(13), reverse(@cThisLine)) - 1))
				set @cThisLine = left(@cThisLine, len(@cThisLine) - charindex(char(13), reverse(@cThisLine)))
			end

			insert into #now (codeLine)
			select listItem
				from notification.dbo.fn_makeTableFromList(@cThisLine, char(13))
				where isnull(rtrim(ltrim(replace(replace(listItem, char(13), ''), char(10), ''))), '') <> ''
		end

		set @bIsChanged = 1
		set @nThisLineNumber = 0
		set @nLastLineNumber = 0
		set @nUkeyLine = 0

		while exists (select top 1 ukey from #then where ukey > @nUkeyLine)
		begin
			set @nThisLineNumber = null

			select top 1
				@nThisLineNumber = b.ukey
				from #then a
				join #now b on replace(replace(replace(replace(notification.dbo.fn_removeFormatting(a.codeLine), 'AppDb_a', ''), 'AppDb_b', ''), 'AppDb_sourcedata_a', ''), 'AppDb_sourcedata_b', '') = replace(replace(replace(replace(notification.dbo.fn_removeFormatting(b.codeLine), 'AppDb_a', ''), 'AppDb_b', ''), 'AppDb_sourcedata_a', ''), 'AppDb_sourcedata_b', '')
					and b.ukey >= @nLastLineNumber
				where a.ukey = @nUkeyLine
				order by b.ukey

			if @nThisLineNumber is null
				update #then set isChanged = 1 where ukey = @nUkeyLine
			else
				set @nLastLineNumber = @nThisLineNumber

			set @nUkeyLine = @nUkeyLine + 1
		end

		set @nThisLineNumber = 0
		set @nLastLineNumber = 0
		set @nUkeyLine = 0

		while exists (select top 1 ukey from #now where ukey > @nUkeyLine)
		begin
			set @nThisLineNumber = null

			select top 1
				@nThisLineNumber = b.ukey
				from #now a
				join #then b on replace(replace(replace(replace(notification.dbo.fn_removeFormatting(a.codeLine), 'AppDb_a', ''), 'AppDb_b', ''), 'AppDb_sourcedata_a', ''), 'AppDb_sourcedata_b', '') = replace(replace(replace(replace(notification.dbo.fn_removeFormatting(b.codeLine), 'AppDb_a', ''), 'AppDb_b', ''), 'AppDb_sourcedata_a', ''), 'AppDb_sourcedata_b', '')
					and b.ukey > @nLastLineNumber
				where a.ukey = @nUkeyLine
				order by b.ukey

			if @nThisLineNumber is null
				update #now set isChanged = 1 where ukey = @nUkeyLine
			else
				set @nLastLineNumber = @nThisLineNumber

			set @nUkeyLine = @nUkeyLine + 1
		end

		--print @bisChanged

		if (select count(*) from #then where isChanged = 1) = 0
			set @bIsChanged = 0
		if (select count(*) from #now where isChanged = 1) = 0
			set @bIsChanged = 0

		-- print @bisChanged

		if @bisChanged = 1
		begin
			set @dChange = case
				when (select count(*) from #then) = 0 then @dYMD_now
				else @dYMD_now
				end

			set @cMessage = case
				when (select count(*) from #then) = 0 --or isnull(@dYMD_then, '') = isnull(@dYMD_now, '')
					then 'Object [' + isnull(@cDatabaseName, '') + '].[' + isnull(@cObjectName, '') + '] was added ' +
						'around ' + convert(varchar(20), isnull(@dYMD_now, ''), 120) + '.' + char(13) + char(13)
				else 'Object [' + isnull(@cDatabaseName, '') + '].[' + isnull(@cObjectName, '') + '] was changed ' +
						'between ' + convert(varchar(20), isnull(@dYMD_then, ''), 120) + ' ' +
						'and ' + convert(varchar(20), isnull(@dYMD_now, ''), 120) + '.' + char(13) + char(13) +
						'Old object text:' + char(13) + replicate('=', 40)
				end

			set @cSubject = 'Object [' + @cDatabaseName + '].[' + @cObjectName + '] was ' +
				case when (select count(*) from #then) = 0 --or isnull(@dYMD_then, '') = isnull(@dYMD_now, '')
					then 'added'
					else 'changed'
					end + ' ' +
					'at ' + convert(varchar(20), isnull(@dYMD_now, getDate()), 120) + '.'

			if (select count(*) from #then) > 0 --and isnull(@dYMD_then, '') <> isnull(@dYMD_now, '')
			begin
				select @cMessage = isnull(@cMessage, '') + char(13) +
					right('00000' + convert(varchar(5), isnull(ukey, 0)), 5) + ': ' +
					replace(replace(isnull(codeLine, ''), char(13), space(0)), char(10), space(0))
					from #then
					where isChanged = 1
					order by ukey
			end

			if (select count(*) from #now) > 0
			begin
				set @cMessage = @cMessage + char(13) + char(13) + 'New object text:' + char(13) + replicate('=', 40)

				select @cMessage = isnull(@cMessage, '') + char(13) +
					right('00000' + convert(varchar(5), isnull(ukey, 0)), 5) + ': ' +
					replace(replace(isnull(codeLine, ''), char(13), space(0)), char(10), space(0))
					from #now
					where isChanged = 1
					order by ukey
			end

			if @cMessage <> ''
				insert into #messages (serverName, [subject], [message], ymd, databaseName, objectName, objectType) values (@cServerName, @cSubject, @cMessage, @dChange, @cDatabaseName, @cObjectName, @cObjectType)
		end


		-- because of the way we handle multi-line objects, we must remove any other mention of this object
		delete from #addedObjects where serverName = @cServerName and objectName = @cObjectName and databaseName = @cDatabaseName
		delete from #droppedObjects where serverName = @cServerName and objectName = @cObjectName and databaseName = @cDatabaseName

	end

	-- so now, anything left in the #droppedObjects table really was dropped

	if @cMessage <> ''
	begin
		insert into #messages (serverName, [subject], [message], ymd, databasename, objectname, objectType)
		select serverName,
			'Object [' + isnull(databaseName, '') + '].[' + isnull(objectName, '') + '] was dropped ' +
				'around ' + convert(varchar(20), isnull(ymd_lastSeen, ''), 120) + '.' as subject,
			'Object [' + isnull(databaseName, '') + '].[' + isnull(objectName, '') + '] was dropped ' +
				'around ' + convert(varchar(20), isnull(ymd_lastSeen, ''), 120) + '.' as message,
			ymd_lastSeen, databasename, objectname, xtype
			from #droppedObjects
	end

	--delete
	---- select *
	--	from #messages
	--	where cast(ymd as time) between '03:00:00' and '08:30:00'
	--		and databaseName in ('AppDb', 'AppDb_lite', 'AppDb_Master')
	--		and objectType = 'V'

	--print 'Removed ' + cast(@@rowcount as varchar(20)) + ' records associated with the A/B flip.'

	delete
	-- select *
		from #messages
		where databaseName in ('SiteFeeds')
			and objectType = 'V'

	delete
	-- select *
		from #messages
		where databaseName in ('AppDb_Mart')
			and objectType in ('C', 'V')

	delete
--		select *
		from #messages
		where databaseName in ('AppDb_SourceData_A', 'AppDb_SourceData_B', 'AppDb_A', 'AppDb_B', 'SiteFeeds', 'AppDb_Inventory')
			and objectname like 'v_%'

	delete
--		select *
		from #messages
		where right(objectName, 1) = '2'
			or objectName like '%old'
			or objectName like '%archive'

	delete
		from #messages
		where databaseName in ('AppDb_Sourcedata_A', 'AppDb_SourceData_b')
			and objectType = 'P'
			and servername not in ('dev03', 'dev03.office', 'etl01', 'etl01.office')
--update #messages
--	set servername = 'NODE'
--	where



--select databaseName, objectName, min(ymd), replace(substring(message, charindex('old object', message), 8000), ' ', ''), count(*)
--	from #messages
--	group by databaseName, objectName, replace(substring(message, charindex('old object', message), 8000), ' ', '')


--select * from #messages

	-- if this is the first pass we've made against this server, don't send out any messages. it'll be all "object added"
	delete #messages
		from #messages a
		join (
			select serverName
				from auditData_objectText (nolock)
				group by serverName
				having sum(case when isnull(ymd_firstSeen, '') <> isnull(ymd_lastSeen, '') then 1 else 0 end) = 0
			) b on a.serverName = b.serverName

	-- write the alerts
	if suser_sname() = 'admin'
	begin
		select distinct ymd, serverName, subject, left(message, 4000), 2 as severity
			from #messages
	end
	else
	begin
		insert into notification..notificationLog_stage (ymd, serverName, subject, message, severity)
		select distinct ymd, serverName, subject, left(message, 4000), 2 as severity
			from #messages
	end

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
