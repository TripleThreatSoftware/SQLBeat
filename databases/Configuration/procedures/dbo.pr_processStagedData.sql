IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_processStagedData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'--alter table runs_stage add ukey_group int
--alter table runs_log add ukey_group int
--GO
CREATE procedure [pr_processStagedData] (@nUkeyGroup int)
as
begin
	declare @nUkeyRun bigint
	declare @dRunStart dateTime
	declare @cInstance varchar(200)
	declare @nCounter int

	set @dRunStart = (select dateAdd(minute, -15, isnull(min(ymd), getDate())) from runs_stage where ukey_group = @nUkeyGroup)

	insert into runs (ymd) values (getDate())

	set @nUkeyRun = scope_identity()

	insert into dm_keyNames (keyName)
	select distinct a.keyName
		from runs_stage a (nolock)
		join notification.dbo.dm_servers b (nolock) on a.serverName = b.serverName
			and b.ukey_group = @nUkeyGroup
		left outer join dm_keyNames c (nolock) on a.keyName = c.keyName
		where c.ukey is null
			and a.ukey_group = @nUkeyGroup

	select a.ukey, @nUkeyRun as ukey_run, b.ukey as ukey_server, c.ukey as ukey_counter, d.ukey as ukey_keyName, a.keyValue, instance
		into #runResults
		from runs_stage a (nolock)
		join notification.dbo.dm_servers b (nolock) on a.serverName = b.serverName
			and b.ukey_group = @nUkeyGroup
		left outer join dm_counters c (nolock) on a.counterName = c.objectName + ''.'' + c.counterName
		left outer join dm_keyNames d (nolock) on a.keyName = d.keyName
		where a.ukey_group = @nUkeyGroup
		order by a.ukey

	insert into runs_data (ukey, ukey_run, ukey_server, ukey_counter, ukey_keyName, keyValue, instance)
	select ukey, ukey_run, ukey_server, ukey_counter, ukey_keyName, keyValue, instance
		from #runResults

	drop table #runResults
	delete from runs_stage with (rowlock) where ukey_group = @nUkeyGroup

	update notification.dbo.dm_servers with (rowlock)
		set configurationCheck = 0,
			eventLogCheck = 0
		from notification.dbo.dm_servers a
		join runs_log b (nolock) on a.serverName = b.serverName
			and b.ymd >= @dRunStart
			and b.message like ''%error%''
			and b.message like ''%connecting to wmi%''
			and b.message not like ''%row handle%''
			and b.ukey_group = @nUkeyGroup
		where a.ukey_group = @nUkeyGroup

	insert into notification.dbo.notificationLog_stage (serverName, isConnectivity, severity, subject, message)
	select
		a.serverName,
		1 as isConnectivity,
		2 as severity,
		''Unable to connect to '' + isnull(a.serverName, '''') + '' using WMI at '' + convert(varchar(20), max(a.ymd), 120) + ''.'' as subject,
		isnull(max(a.message), '''') + char(13) + char(13) +
			''Future connections using WMI are DISABLED.''
		from runs_log a (nolock)
		where a.ymd >= @dRunStart
			and a.message like ''%error%''
			and a.message like ''%connecting to wmi%''
			and a.message not like ''%row handle%''
--			and a.message not like ''%runtime error%''
			and a.ukey_group = @nUkeyGroup
		group by a.serverName
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
