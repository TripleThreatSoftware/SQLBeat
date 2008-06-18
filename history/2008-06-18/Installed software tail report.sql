	declare @dStartDate dateTime
	declare @dEndDate dateTime

	set @dStartDate = '2008-02-01'

--	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -48, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	select ukey_server,
		min(case when a.ymd >= @dStartDate and a.ymd <= @dEndDate then a.ukey else null end) as ukey_lastRun,
		max(case when a.ymd >= @dStartDate and a.ymd <= @dEndDate then a.ukey else null end) as ukey_thisrun
		into #runHistory
		from runs a (nolock)
		join (select distinct ukey_run, ukey_server from runs_data (nolock) ) b on a.ukey = b.ukey_run
		group by b.ukey_server

	-- installed since last check
	select d.serverName, 'Installed' as details,
		b.programName, isnull(b.installDate, getDate()) as installDate, b.version

		into #changeHistory

		from #runHistory a
		join runs_data b on a.ukey_thisRun = b.ukey_run
			and a.ukey_server = b.ukey_server
		left outer join runs_data c on a.ukey_lastRun = c.ukey_run
			and a.ukey_server = c.ukey_server
			and (
				isnull(b.programName, '') = isnull(c.programName, '')
				and isnull(b.installDate, '') = isnull(c.installDate, '')
				and isnull(b.version, '') = isnull(c.version, '')
				)
		join notification..dm_servers d on a.ukey_server = d.ukey
		where c.ukey is null
			and a.ukey_lastRun is not null
	union
	-- removed since last check
	select d.serverName, 'Removed' as details,
		b.programName, isnull(b.installDate, getDate()), b.version
		from #runHistory a
		join runs_data b on a.ukey_lastRun = b.ukey_run
			and a.ukey_server = b.ukey_server
		left outer join runs_data c on a.ukey_thisRun = c.ukey_run
			and a.ukey_server = c.ukey_server
			and (
				isnull(b.programName, '') = isnull(c.programName, '')
				and isnull(b.installDate, '') = isnull(c.installDate, '')
				and isnull(b.version, '') = isnull(c.version, '')
				)
		join notification..dm_servers d on a.ukey_server = d.ukey
			and d.installedSoftwareCheck = 1
			and d.isEnabled = 1
		where c.ukey is null
		order by d.serverName, details, b.programName

	select *
		from #changeHistory
		order by installDate, serverName

	drop table #runHistory
	drop table #changeHistory
