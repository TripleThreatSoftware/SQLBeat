use [configuration]
GO
--alter table runs_stage add ukey_group int
--alter table runs_log add ukey_group int
--GO
ALTER procedure [dbo].[pr_processStagedData] (@nUkeyGroup int)
as
begin
	declare @nUkeyRun bigint
	declare @dRunStart dateTime
	declare @cInstance varchar(200)
	declare @nCounter int

	set @dRunStart = (select dateAdd(minute, -5, min(ymd)) from runs_stage where ukey_group = @nUkeyGroup)

	insert into runs (ymd) values (getDate())

	set @nUkeyRun = scope_identity()

	insert into dm_keyNames (keyName)
	select distinct a.keyName
		from runs_stage a
		join notification.dbo.dm_servers b (nolock) on a.serverName = b.serverName
			and b.ukey_group = @nUkeyGroup
		left outer join dm_keyNames c (nolock) on a.keyName = c.keyName
		where a.ukey_group = @nUkeyGroup
			and c.ukey is null

	select a.ukey, @nUkeyRun as ukey_run, b.ukey as ukey_server, c.ukey as ukey_counter, d.ukey as ukey_keyName, a.keyValue, instance,
		convert(int, 0) as rowNum
		into #runResults
		from runs_stage a
		join notification.dbo.dm_servers b (nolock) on a.serverName = b.serverName
			and b.ukey_group = @nUkeyGroup
		left outer join dm_counters c (nolock) on a.counterName = c.objectName + '.' + c.counterName
		left outer join dm_keyNames d (nolock) on a.keyName = d.keyName
		where a.ukey_group = @nUkeyGroup
		order by a.ukey

	set @nCounter = 0

	update #runResults
		set
			@nCounter = rownum =
				case when convert(varchar(20), ukey_server) + '|' +
					convert(varchar(20), ukey_counter) + '|' +
					convert(varchar(20), instance) = @cInstance
					then @nCounter + 1 else 0 end,
			@cInstance = convert(varchar(20), ukey_server) + '|' +
				convert(varchar(20), ukey_counter) + '|' +
				convert(varchar(20), instance)

	insert into runs_data (ukey, ukey_run, ukey_server, ukey_counter, ukey_keyName, keyValue, instance)
	select ukey, ukey_run, ukey_server, ukey_counter, ukey_keyName, keyValue, instance
		from #runResults

--	insert into runs_data_condensed (ukey_run, ukey_server, condensedData)
--	select a.ukey_run, a.ukey_server, a.condensed
--		from #runResults a
--		join (
--			select ukey_run, ukey_server, ukey_counter, instance, max(rownum) as rownum
--				from #runResults
--				group by ukey_run, ukey_server, ukey_counter, instance
--			) b on a.ukey_run = b.ukey_run
--				and a.ukey_server = b.ukey_server
--				and a.ukey_counter = b.ukey_counter
--				and a.instance = b.instance
--				and a.rownum = b.rownum

	drop table #runResults
	delete from runs_stage with (rowlock) where ukey_group = @nUkeyGroup

	update notification.dbo.dm_servers with (rowlock)
		set configurationCheck = 0,
			eventLogCheck = 0
		from notification.dbo.dm_servers a
		join runs_log b (nolock) on a.serverName = b.serverName
			and b.ymd >= @dRunStart
			and b.message like '%error%'
			and b.message like '%connecting to wmi%'
			and b.ukey_group = @nUkeyGroup
		where a.ukey_group = @nUkeyGroup

	update notification.dbo.dm_servers with (rowlock)
		set configurationCheck = 0,
			eventLogCheck = 0
		from notification.dbo.dm_servers a
		join runs_log b (nolock) on a.serverName = b.serverName
			and b.ymd >= @dRunStart
			and b.message like '%object required%'
			and b.ukey_group = @nUkeyGroup
		where a.ukey_group = @nUkeyGroup

	insert into notification.dbo.notificationLog_stage (serverName, isConnectivity, severity, subject, message)
	select
		a.serverName,
		1 as isConnectivity,
		2 as severity,
		'Unable to connect to ' + isnull(a.serverName, '') + ' using WMI at ' + convert(varchar(20), min(a.ymd), 120) + '.' as subject,
		isnull(a.message, '') + char(13) + char(13) +
			'Future connections using WMI are DISABLED.'
		from runs_log a (nolock)
		where a.ymd >= @dRunStart
			and a.message like '%error%'
			and a.message like '%connecting to wmi%'
			and a.message not like '%runtime error%'
			and a.ukey_group = @nUkeyGroup
		group by a.serverName, a.message

	insert into notification.dbo.notificationLog_stage (serverName, isConnectivity, severity, subject, message)
	select
		a.serverName,
		1 as isConnectivity,
		2 as severity,
		'Had issues reading ' + isnull(a.serverName, '') + ' using WMI at ' + convert(varchar(20), min(a.ymd), 120) + '.' as subject,
		isnull(a.message, '') + char(13) + char(13) +
			'Future connections using WMI are DISABLED.'
		from runs_log a (nolock)
		where a.ymd >= @dRunStart
			and a.message like '%object required%'
			and a.ukey_group = @nUkeyGroup
		group by a.serverName, a.message
end
