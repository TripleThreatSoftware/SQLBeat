declare @dStartdate dateTime
declare @dEndDate dateTime

	set @dStartDate = '2008-08-13'
	set @dEndDate = getDate()

	select b.ymd, ukey_run, ukey_server, count(*) as numEntries, identity(int) as ukey
		into #runAverages
		from runs_data a (nolock)
		join runs b (nolock) on a.ukey_run = b.ukey
			and b.ymd >= @dStartDate
			and b.ymd <= @dEndDate
		group by b.ymd, ukey_run, ukey_server
		order by ukey_server, ukey_run

	select ukey_server,
		min(ukey) as ukey_start,
		max(ukey) as ukey_stop,
		min(ymd) as ymd_start,
		max(ymd) as ymd_stop
		into #serverRanges
		from #runAverages
		group by ukey_server

	delete #runAverages
		from #runAverages a
		join (
			select ukey_server, avg(numEntries) as numEntries
				from #runAverages
				group by ukey_server
			) b on a.ukey_server = b.ukey_server
				and (
					a.numEntries >= b.numEntries * 5
					or a.numEntries <= b.numEntries * .25
					)

	select a.ukey_server, a.programName, min(installDate) as installDate, min(version) as version, min(c.ymd_start) as ymd
		into #startState
		from runs_data a
		join #runAverages b on a.ukey_server = b.ukey_server
			and a.ukey_run = b.ukey_run
		join #serverRanges c on a.ukey_server = c.ukey_server
			and b.ukey <= c.ukey_start + 2
		group by a.ukey_server, a.programName

	select a.ukey_server, a.programName, max(installDate) as installDate, max(version) as version, max(c.ymd_stop) as ymd
		into #endState
		from runs_data a
		join #runAverages b on a.ukey_server = b.ukey_server
			and a.ukey_run = b.ukey_run
		join #serverRanges c on a.ukey_server = c.ukey_server
			and b.ukey >= c.ukey_stop - 2
		group by a.ukey_server, a.programName

--select a.*
--	from #startState a
--	join notification..dm_servers b on a.ukey_server = b.ukey
--		and b.servername = 'devoradb03'
--select a.*
--	from #endState a
--	join notification..dm_servers b on a.ukey_server = b.ukey
--		and b.servername = 'devoradb03'

	select
		d.serverName, 'Removed' as details, a.programName, a.installDate, a.version, a.ymd as lastSeen, null as firstSeen
		into #changeResults
		from #startState a
		left outer join #endState b on a.ukey_server = b.ukey_server
			and (
				isnull(a.programName, '') = isnull(b.programName, '')
				and isnull(a.installDate, '') = isnull(b.installDate, '')
				and isnull(a.version, '') = isnull(b.version, '')
				)
		join notification..dm_servers d on a.ukey_server = d.ukey
			and d.installedSoftwareCheck = 1
			and d.isEnabled = 1
		where b.ukey_server is null
	union
	select
		d.serverName, 'Installed' as details, a.programName, a.installDate, a.version, null as lastSeen, a.ymd as firstSeen
		from #endState a
		left outer join #startState b on a.ukey_server = b.ukey_server
			and (
				isnull(a.programName, '') = isnull(b.programName, '')
				and isnull(a.installDate, '') = isnull(b.installDate, '')
				and isnull(a.version, '') = isnull(b.version, '')
				)
		join notification..dm_servers d on a.ukey_server = d.ukey
			and d.installedSoftwareCheck = 1
			and d.isEnabled = 1
		where b.ukey_server is null

--	select left(installDate, 4) + '-' + substring(installDate, 5, 2) + '-' + substring(installDate, 7, 2)
--		from #changeResults

	delete from #changeResults
		where isdate(left(installDate, 4) + '-' + substring(installDate, 5, 2) + '-' + substring(installDate, 7, 2)) = 1
			and len(installDate) = 8
			and convert(dateTime, left(installDate, 4) + '-' + substring(installDate, 5, 2) + '-' + substring(installDate, 7, 2)) < @dStartDate
			and details = 'Installed'

	select *
		from #changeResults
		order by servername, details, programName

go

drop table #runAverages
drop table #startState
drop table #endState
drop table #serverRanges
drop table #changeResults
