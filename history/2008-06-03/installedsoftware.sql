IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'sqlnotification')
CREATE USER [sqlnotification] FOR LOGIN [sqlnotification] WITH DEFAULT_SCHEMA=[dbo]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_returnDigits]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE         function [fn_returnDigits](@cSomeString varchar(50), @lStopAtFirstNonNumber bit = 0)
returns bigInt
as
begin

	declare @nLength int
	declare @nCounter int
	declare @cReturnValue varchar(50)
	declare @nReturnValue bigint
	declare @cCharacter varchar(1)

	set @cReturnValue = ''''
	set @cSomeString = rtrim(ltrim(@cSomeString))

	if @cSomeString is not null
	begin
		set @nLength = len(@cSomeString)
		set @nCounter = 1
		while @nCounter <= @nLength
		begin
			set @cCharacter = substring(@cSomeString, @nCounter, 1)
			if @cCharacter in (''1'', ''2'', ''3'', ''4'', ''5'', ''6'', ''7'', ''8'', ''9'', ''0'')
				set @cReturnValue = rtrim(@cReturnValue) + @cCharacter
			else
			begin
				if @lStopAtFirstNonNumber = 1 and len(@cReturnValue) > 0
					break
			end

			set @nCounter = @nCounter + 1
		end
	end

	if isnumeric(@cReturnValue) = 1 and @cReturnValue < ''9223372036854775807'' and len(@cReturnValue) < 15
		set @nReturnValue = convert(bigint, @cReturnValue)
	else
		set @nReturnValue = 0

	return @nReturnValue
end
'
END
go

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_scanForExecutables]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE  procedure [pr_scanForExecutables]
as
begin

	declare @cComputerName varchar(200)
	declare @cSQLString nvarchar(4000)
	declare @nUkeyRun int

	insert into executableScan_runs (ymd) values (getDate())

	set @nUkeyRun = scope_identity()

	create table #results (outputLine varchar(500))

	set @cComputerName = ''''

	while exists (select top 1 computerName from monitoredComputers where computerName > @cComputerName and isEnabled = 1 order by computerName)
	begin
		set @cComputerName = (select top 1 computerName from monitoredComputers where computerName > @cComputerName and isEnabled = 1 order by computerName)

		set @cSQLString = ''dir \\'' + @cComputerName + ''\c$\*.exe /s/b''

		insert into #results
		exec master..xp_cmdshell @cSQLString

		insert into executableScan (computerName, [fileName], ukey_run)
		select @cComputerName, outputLine, @nUkeyRun
			from #results
			where outputLine not like ''%permission denied%''

		update monitoredComputers
			set lastCheck = getDate()
			where computerName = @cComputerName

		truncate table #results
	end

	drop table #results

end
'
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_processStagedData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_processStagedData]
as
begin
	declare @nUkeyRun int
	declare @dLastRun dateTime

	set	@dLastRun = (select max(ymd) from runs_log where [message] = ''----- Monitoring Started ----'')

	if (select count(*) from runs_stage (nolock)) > 0
	begin
		insert into runs (ymd) values (getDate())

		set @nUkeyRun = scope_identity()

		insert into runs_data (ukey, ukey_run, ukey_server, programName, installDate, version)
		select a.ukey, @nUkeyRun, b.ukey as ukey_server, programName, installDate, version
			from runs_stage a
			join notification.dbo.dm_servers b on a.serverName = b.serverName

		truncate table runs_stage
	end

	insert into notification..notificationLog_stage (message, severity, subject, serverName)
	select
		''Installed Software scan failed. Further scans disabled.'' + char(13) + char(13) + [message] as [message],
		2 as severity,
		''Installed Software scan error for '' + isnull(serverName, ''N/A'') + '' at '' + convert(varchar(20), ymd, 120) as [subject],
		serverName
		from runs_log
		where [message] like ''%error%''
			and (
				[message] like ''%denied%''
				or [message] like ''%rpc%''
			)
			and ymd >= @dLastRun

	update notification..dm_servers
		set installedSoftwareCheck = 0
		from notification..dm_servers a
		join (
			select distinct serverName
				from runs_log
				where [message] like ''%error%''
					and ymd >= @dLastRun
					and (
						[message] like ''%denied%''
						or [message] like ''%rpc%''
					)
			) b on a.serverName = b.serverName

	update notification..dm_servers
		set lastInstalledSoftwareCheck = b.ymd
		from notification..dm_servers a
		join (
			select serverName, max(ymd) as ymd
				from runs_log
				where ymd >= @dLastRun
					and serverName is not null
				group by serverName
			) b on a.serverName = b.serverName
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_installedSoftwareChanges]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_installedSoftwareChanges]
as
begin

	select ukey_server,
		max(ukey_run) as ukey_thisrun,
		convert(int, null) as ukey_lastrun
		into #runHistory
		from (select distinct ukey_server, ukey_run from runs_data) a
		group by ukey_server

	delete #runHistory
		from #runHistory a
		join runs b on a.ukey_thisRun = b.ukey
			and b.ymd < dateAdd(day, -3, getdate())

	update #runHistory
		set ukey_lastRun = b.ukey_run
		from #runHistory a
		join (
			select a.ukey_server, a.ukey_thisRun, max(b.ukey_run) as ukey_run
				from #runHistory a
				join (select ukey_server, ukey_run from runs_data group by ukey_server, ukey_run having count(*) > 5) b on a.ukey_server = b.ukey_server
					and a.ukey_thisRun > b.ukey_run
				group by a.ukey_server, a.ukey_thisRun
			) b on a.ukey_server = b.ukey_server
				and a.ukey_thisRun = b.ukey_thisRun

	--select * from runs

	-- installed since last check
	select d.serverName, ''Installed'' as details,
		b.programName, b.installDate, b.version

		into #changeHistory

		from #runHistory a
		join runs_data b on a.ukey_thisRun = b.ukey_run
			and a.ukey_server = b.ukey_server
		left outer join runs_data c on a.ukey_lastRun = c.ukey_run
			and a.ukey_server = c.ukey_server
			and (
				isnull(b.programName, '''') = isnull(c.programName, '''')
				and isnull(b.installDate, '''') = isnull(c.installDate, '''')
				and isnull(b.version, '''') = isnull(c.version, '''')
				)
		join notification..dm_servers d on a.ukey_server = d.ukey
		where c.ukey is null
			and a.ukey_lastRun is not null
	union
	-- removed since last check
	select d.serverName, ''Removed'' as details,
		b.programName, b.installDate, b.version
		from #runHistory a
		join runs_data b on a.ukey_lastRun = b.ukey_run
			and a.ukey_server = b.ukey_server
		left outer join runs_data c on a.ukey_thisRun = c.ukey_run
			and a.ukey_server = c.ukey_server
			and (
				isnull(b.programName, '''') = isnull(c.programName, '''')
				and isnull(b.installDate, '''') = isnull(c.installDate, '''')
				and isnull(b.version, '''') = isnull(c.version, '''')
				)
		join notification..dm_servers d on a.ukey_server = d.ukey
			and d.installedSoftwareCheck = 1
			and d.isEnabled = 1
		where c.ukey is null
		order by d.serverName, details, b.programName

	select *,
		identity(int) as ukey
		into #results
		from #changeHistory

	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @cThisServer varchar(200)

	set @cThisServer = ''''

	while exists (select top 1 ukey from #results where serverName > @cThisServer)
	begin
		select top 1 @cThisServer = serverName from #results where serverName > @cThisServer

		set @cThisMessage = char(13) +
			''The following items have changed since the last check'' + char(13) + char(13) +
			left(''Server'' + space(15), 15) + '' '' +
			left(''Details'' + space(10), 10) + '' '' +
			left(''Program'' + space(50), 50) + '' '' +
			left(''Date'' + space(10), 10) + '' '' +
			left(''Version'' + space(20), 20) + '' '' + char(13) +

			replicate(''='', 15) + '' '' +
			replicate(''='', 10) + '' '' +
			replicate(''='', 50) + '' '' +
			replicate(''='', 10) + '' '' +
			replicate(''='', 20) + '' '' + char(13)

		select
			@cThisMessage = @cThisMessage +
				left(isnull(serverName, ''-'') + space(15), 15) + '' '' +
				left(isnull(details, ''-'') + space(10), 10) + '' '' +
				left(isnull(programName, ''-'') + space(50), 50) + '' '' +
				left(isnull(installDate, ''-'') + space(10), 10) + '' '' +
				left(isnull(version, ''-'') + space(20), 20) + '' '' + char(13)
			from #results
			where serverName = @cThisServer

		set @cThisSubject = ''Installed software changes for '' + convert(varchar(10), getDate(), 120)

		insert into notification..notificationLog_stage (serverName, subject, message, severity, isInstalledSoftware) values (
			@cThisServer, @cThisSubject, @cThisMessage, 2, 1)

	end

	drop table #runHistory
	drop table #results
	drop table #changeHistory
end
-- select top 100 * from notification..notificationLog order by ukey desc
-- delete from notification..notificationLog where ukey in (29609,29608,29607)
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_installedSoftware]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_installedSoftware]
as
begin
	declare @nUkeyRun int
	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(200)

	declare @results table (groupName varchar(100), serverName varchar(200), programName varchar(500), installDate varchar(100), version varchar(100))
--	create table #results (groupName varchar(100), serverName varchar(200), programName varchar(500), installDate varchar(100), version varchar(100))

	insert into @results (groupName, serverName, programName, installDate, version)
	select d.groupName, a.serverName, c.programName, c.installDate, c.version
		from notification..dm_servers a
		join (
			select ukey_server, max(ukey_run) as ukey_run
				from runs_data a
				group by ukey_server
			) b on a.ukey = b.ukey_server
		join runs_data c on b.ukey_server = c.ukey_server
			and b.ukey_run = c.ukey_run
		join notification..dm_serverGroups d on a.ukey_group = d.ukey

	set @cServerName = ''''

	while exists (select top 1 settingValue from notification..dm_settings where settingName = ''Sister server'' and settingValue > @cServerName)
	begin
		select top 1
			@cServerName = settingValue
			from notification..dm_settings
			where settingName = ''Sister server''
				and settingValue > @cServerName
			order by settingValue

		set @cSQLString = ''
	select d.groupName, a.serverName, c.programName, c.installDate, c.version
		from ['' + @cServerName + ''].notification.dbo.dm_servers a
		join (
			select ukey_server, max(ukey_run) as ukey_run
				from ['' + @cServerName + ''].installedSoftware.dbo.runs_data a
				group by ukey_server
			) b on a.ukey = b.ukey_server
		join ['' + @cServerName + ''].installedSoftware.dbo.runs_data c on b.ukey_server = c.ukey_server
			and b.ukey_run = c.ukey_run
		join ['' + @cServerName + ''].notification.dbo.dm_serverGroups d on a.ukey_group = d.ukey''

		insert into @results (groupName, serverName, programName, installDate, version)
		exec sp_executeSQL @cSQLString
	end

	select *
		from @results
		order by groupName, serverName, programName

--	drop table #results
end
'
END
