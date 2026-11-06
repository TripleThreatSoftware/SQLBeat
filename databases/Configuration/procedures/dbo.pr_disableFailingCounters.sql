/****** Object:  StoredProcedure [dbo].[pr_disableFailingCounters]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_disableFailingCounters] (@nUkeyGroup int)
as
begin

	delete from runs_stage with (tablock) where ukey_group not in (select distinct ukey from notification..dm_serverGroups)
	delete from runs_stage with (tablock) where serverName not in (select distinct serverName from notification..dm_servers)

return
--	update notification..dm_servers
--		set configurationCheck = 1,
--			eventLogCheck = 1,
--			installedSoftwareCheck = 1
--		where wmiStatus = 'SUCCESS'

	select ymd, servername, message
		into #failures
		from runs_log
		where (
				message like '%no items found%'
				or message like '%invalid class%'
				or message like '%generic failure%'
				or message like '%provider load failure%'
				or message like '%provider failure%'
			)
			and ymd >= dateAdd(day, -1, getDate())
			and ukey_group = @nUkeyGroup

	update dm_serverCounters
		set isEnabled = 0
		from dm_serverCounters a
		join notification..dm_servers b on a.ukey_server = b.ukey
		join dm_counters c on a.ukey_counter = c.ukey
		join (
			select a.serverName,
				ltrim(right(c.message, charindex(' ', reverse(c.message)))) as counterName,
				max(a.ymd) as ymd
				from #failures a
				join (
					select a.ymd, a.serverName, max(b.ukey) as ukey
						from #failures a
						join runs_log b on a.serverName = b.serverName
							and b.ymd < a.ymd
							and b.message like '%processing%'
						group by a.ymd, a.serverName
					) b on a.ymd = b.ymd
						and a.serverName = b.serverName
				join runs_log c on a.serverName = c.serverName
					and b.ukey = c.ukey
				where a.serverName <> ''
				group by a.serverName, right(c.message, charindex(' ', reverse(c.message)))
			) d on b.serverName = d.serverName
				and c.counterName = d.counterName
	--			and isnull(a.lastCheck, '') < d.ymd

end
GO
