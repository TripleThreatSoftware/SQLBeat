-- ================================================================================================
-- Notification.dbo.pr_readCPUCounters
--
-- Connects to each Windows server and logs a snapshot of CPU load, read with PowerShell, to
-- CPUCounter_Log. Job: "CPU Counter Check - All Servers".
-- ================================================================================================
/****** Object:  StoredProcedure [dbo].[pr_readCPUCounters]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_readCPUCounters]
as
begin

	declare @cSQLString nvarchar(4000)
	declare @cScriptPath varchar(500)
	declare @cDateString varchar(500)
	declare @cWideString varchar(8000)
	declare @nUkey int
	declare @cServerName varchar(200)
	declare @nUkeyServer int
	declare @nCPUCountThreshold_core decimal(10,2)
	declare @bKeepCores bit


	--trim cpuCounter_log table
	delete from cpuCounter_log
	where runymd < dateadd(hour, -48, getdate())

	create table #results (ukey int identity, wideString varchar(8000), serverName varchar(500))
	create clustered index ix_tmp_results on #results (ukey) with fillfactor = 60

	create table #servers (ukey int identity, servername varchar(200), ukey_server int, cpuCountThreshold_core decimal(10,2))

	if not exists (select top 1 ukey from dm_settings where settingName = 'shared folder')
		insert into dm_settings (settingName, settingValue) values ('shared folder', 'C:\SHARED\')

	set @cScriptPath = (select top 1 settingValue from dm_settings where settingName = 'shared folder')

	if right(@cScriptPath, 1) <> '\'
		set @cScriptPath = @cScriptPath + '\'

	set @cSQLString = 'powershell -file ' + @cScriptPath + 'readCPUfromCounters.ps1'

	insert into #results (wideString)
	exec master..xp_cmdshell @cSQLString

	if exists (select top 1 widestring from #results where wideString like '%denied%' or wideString like '%error%')
	begin
		set @cWideString = ''
		select @cWideString = @cWideString + wideString + '<br>' from #results where wideString like '%denied%' or wideString like '%error%'

		insert into notificationLog_stage (serverName, subject, message, severity) values (@@servername, 'pr_readCPUCounters error', @cWideString, 2)
	end

	if (select count(*) from cpuCounter_raw (nolock)) > 0
	begin

		update cpuCounter_raw
			set [Computer Name] = left([Computer Name], charindex('.', [Computer Name])-1)


		insert into #servers (servername, ukey_server, cpuCountThreshold_core)
		select distinct
			a.[Computer Name],
			isnull(b.ukey, 0),
			convert(int, '90') as cpuCountThreshold_core
			from cpuCounter_raw a (nolock)
			left join dm_servers b (nolock) on a.[Computer Name] = b.serverName

		update #servers
			set ukey_server = b.ukey
			from #servers a (nolock)
			join dm_servers b (nolock) on a.servername = b.friendlyName
			where a.ukey_server = 0

		set @nUkey = 0
		set @bKeepCores = 0

		while exists (select top 1 ukey from #servers where ukey > @nUkey)
		begin
			select top 1
				@nUkey = ukey,
				@cServerName = serverName,
				@nUkeyServer = ukey_server,
				@nCPUCountThreshold_core = cpuCountThreshold_core
				from #servers
				where ukey > @nUkey
				order by ukey

			set @bKeepCores = case when exists (
										select
											[Computer Name],
											max(average)
											from cpuCounter_raw (nolock)
											where [Computer Name] = @cServerName
												and name not in ('_total', '0,_total','1,_total')
											group by [Computer Name]
											having max(average) > @nCPUCountThreshold_core
									)
									then 1 else 0 end

			insert into cpuCounter_log (serverName, ukey_server, [timestamp], name, average, maximum, runymd)
			select
				[Computer Name] as computerName,
				@nUkeyServer,
				[timestamp],
				name,
				average,
				maximum,
				getDate()
				from cpuCounter_raw (nolock)
				where [Computer Name] = @cServerName
					and (name in ('_total', '0,_total','1,_total')
						or isnull(@bKeepCores, 0) = 1)

			delete from cpuCounter_raw
				where [Computer Name] = @cServerName

		end

		truncate table cpuCounter_raw
	end

	drop table #servers
	drop table #results
end
GO
