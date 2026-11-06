/****** Object:  StoredProcedure [dbo].[pr_readWMIObjects]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_readWMIObjects 37
-- select * from runs_stage where serverName in ('appweb01') order by ymd desc
--  and counterName in ('Win32_PhysicalMemory', 'Win32_PerfFormattedData_PerfProc_Process')
-- truncate table runs_log
-- select * from runs_log order by ymd desc

CREATE procedure [dbo].[pr_readWMIObjects] (@nUkeyGroup int)
as
begin

	set nocount on

	declare @cServerName varchar(500)
	declare @nUkeyServer int
	declare @nUkeyServerCounter int
	declare @nUkeyCounter int
	declare @cCounterName varchar(200)
	declare @cObjectName varchar(200)
	declare @cUserName varchar(100)
	declare @cPassword varchar(100)
	declare @dLastEventLogCheck dateTime
	declare @cSQLString nvarchar(4000)
	declare @cScriptPath varchar(2000)
	declare @cFieldName varchar(200)
	declare @nUkey int
	declare @cWideString varchar(8000)
	declare @nRowCount int
	declare @cLastFieldName varchar(100)
	declare @cKeyName varchar(200)
	declare @cKeyValue varchar(8000)
	declare @nInstance int

	insert into runs_log (message, serverName, ukey_group) values ('Monitoring Started', null, @nUkeyGroup)

	Select
		a.serverName, a.wmiUserName, a.wmiPassword, a.ukey as ukey_server,
		b.ukey as ukey_serverCounter,
		c.ukey as ukey_counter,
		c.counterName,
		c.objectName,
		identity(int) as ukey
		into #readObjects
		from notification.dbo.dm_servers a (nolock)
		join configuration.dbo.dm_serverCounters b (nolock) on a.ukey = b.ukey_server
			and b.isEnabled = 1
		join configuration.dbo.dm_counters c (nolock) on b.ukey_counter = c.ukey
			and c.isEnabled = 1
		where a.isEnabled = 1
			and a.configurationCheck = 1
			and a.isServerPingable = 1
			and a.ukey_group = @nUkeyGroup
			and (a.configurationCheckSleepUntil is null or getDate() > configurationCheckSleepUntil)
			and dateDiff(minute, isnull(b.lastCheck, '1900-01-01'), getDate()) > isnull(b.checkMinuteInterval, isnull(c.checkMinuteInterval, 60))

	set @nRowCount = @@rowcount

	insert into runs_log (message, serverName, ukey_group) values ('Found ' + convert(varchar(20), @nRowCount) + ' counters to check', 0, @nUkeyGroup)


	set @cServerName = ''

	if not exists (select top 1 ukey from notification.dbo.dm_settings where settingName = 'Shared Files')
		insert into notification.dbo.dm_settings (settingName, settingValue) values ('Shared Files', 'C:\SHARED\')

	set @cScriptPath = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'Shared Files')

	create table #results (ukey int identity, wideString varchar(8000), serverName varchar(500), counterName varchar(200))
	create table #objectData (serverName varchar(200), counterName varchar(200), keyName varchar(200), keyValue varchar(8000), instance int)

	set @nUkey = 0

	while exists (
		select top 1 ukey
			from #readObjects (nolock)
			where ukey > @nUkey
		)
	begin
		select top 1
			@cServerName = serverName,
			@nUkeyServer = ukey_server,
			@cUserName = wmiUserName,
			@cPassword = wmiPassword,
			@nUkeyServerCounter = ukey_serverCounter,
			@nUkeyCounter = ukey_counter,
			@cCounterName = counterName,
			@cObjectName = objectName,
			@nUkey = ukey
			from #readObjects (nolock)
			where ukey > @nUkey
			order by ukey

		--Adding APC SNMP handling here.  04/29/2014.
		if @cObjectName = 'APCSNMP'
--			if isnull(@cUserName, '') = ''
--			set @cSQLString = 'powershell -file ' + @cScriptPath + 'readSNMPfromAPCs.ps1'
--			else
				set @cSQLString = 'powershell -file ' + @cScriptPath + 'readSNMPfromAPCs.ps1'
		else
			if isnull(@cUserName, '') = ''
				set @cSQLString = 'powershell -file ' + @cScriptPath + 'readWMI.ps1 -cServerName ' + @cServerName + ' -cObjectName ' + @cCounterName
			else
				set @cSQLString = 'powershell -file ' + @cScriptPath + 'readWMI.ps1 -cServerName ' + @cServerName + ' -cUserName "' + @cUsername + '" -cPassword "' + @cPassword + '" -cObjectName ' + @cCounterName


--		print @cSQLString

		insert into #results (wideString)
		exec master..xp_cmdshell @cSQLString

		set @nRowCount = @@rowcount

		insert into runs_log (message, serverName, ukey_group) values ('Read ' + convert(varchar(20), @nRowCount) + ' rows of data for ' + isnull(@cCounterName, 'N/A'), @cServerName, @nUkeyGroup)

		update #results set serverName = @cServerName, counterName = @cObjectName + '.' + @cCounterName where serverName is null

		update dm_serverCounters with (rowlock)
			set lastCheck = getDate()
			where ukey_server = @nUkeyServer
				and ukey_counter = @nUkeyCounter

		update notification.dbo.dm_servers with (rowlock)  set lastConfigurationCheck = getDate() where serverName = @cServerName
	end
	create index ix_tmp_results on #results (ukey) with fillfactor = 90

--select * from #results

	set @nUkey = 0
	set @cKeyName = ''
	set @cKeyValue = ''
	set @nInstance = 0

	while exists (select top 1 ukey from #results where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@cWideString = wideString,
			@cServerName = serverName,
			@cCounterName = counterName
			from #results
			where ukey > @nUkey
			order by ukey

		set @cWideString = rtrim(ltrim(@cWideString))

		if @cWideString = '*/*/*'
		begin
			set @nInstance = @nInstance + 1
			continue
		end

		if left(@cWideString, 2) = '||'
		begin
			if isnull(@cKeyName, '') <> ''
				insert into #objectData (instance, keyName, keyValue, counterName, serverName) values (@nInstance, @cKeyName, @cKeyValue, @cCounterName, @cServerName)

			set @cKeyName = substring(@cWideString, 3, 200)
			set @cKeyName = rtrim(ltrim(left(@cKeyName, charindex('~~', @cKeyName) - 1)))

			set @cKeyValue = ''
		end

		if charindex('~~', @cWideString) > 0
			set @cWideString = substring(@cWideString, charindex('~~', @cWideString) + 2, 8000)

		set @cKeyValue = rtrim(ltrim(left(@cKeyValue + @cWideString, 8000)))

	end

	insert into runs_stage (serverName, counterName, keyName, keyValue, instance, ukey_group)
	select serverName, counterName, keyName, keyValue, instance, @nUkeyGroup
		from #objectData

	set @nRowCount = @@rowcount
	insert into runs_log (message, serverName, ukey_group) values ('Added ' + convert(varchar(20), @nRowCount) + ' events to be staged', '', @nUkeyGroup)

	drop table #results
	drop table #objectData

end
GO
