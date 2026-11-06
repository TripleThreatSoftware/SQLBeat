/****** Object:  StoredProcedure [dbo].[pr_sendProcessResourceWarnings]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_sendProcessResourceWarnings]
as
begin

	declare @cThisProcessName varchar(100)
	declare @cThisMessage varchar(4000)
	declare @cThisSubject varchar(500)
	declare @nThisUkey int

	select a.ukey, ukey_server, ukey_run, keyName, keyValue, convert(varchar(100), '') as processName
		into #runningProcesses
		from runs_data a
		join dm_counters b on a.ukey_counter = b.ukey
			and b.counterName = 'Win32_PerfFormattedData_PerfProc_Process'
		join dm_keyNames c on a.ukey_keyName = c.ukey
		where c.keyName in ('name', 'pageFileBytes', 'pageFileBytesPeak', 'poolNonPagedBytes', 'poolPagedBytes', 'privateBytes', 'threadCount')
		order by a.ukey_run, a.ukey_server, b.counterName, a.ukey

	set @cThisProcessName = ''

	update #runningProcesses
		set @cThisProcessName = processName = case when keyName = 'name' then keyValue else @cThisProcessName end


	select c.serverName, b.ymd,
		a.processName, a.pageFileBytes, a.pageFileBytesPeak, a.poolNonPagedBytes, a.poolPagedBytes, a.privateBytes, a.threadCount,
		a.ukey_run
		into #processSummary
		from (
			select ukey_server, ukey_run,
					processName,
					sum(case when keyName = 'pageFileBytes' then convert(bigint, keyValue) else null end) as pageFileBytes,
					sum(case when keyName = 'pageFileBytesPeak' then convert(bigint, keyValue) else null end) as pageFileBytesPeak,
					sum(case when keyName = 'poolNonPagedBytes' then convert(bigint, keyValue) else null end) as poolNonPagedBytes,
					sum(case when keyName = 'poolPagedBytes' then convert(bigint, keyValue) else null end) as poolPagedBytes,
					sum(case when keyName = 'privateBytes' then convert(bigint, keyValue) else null end) as privateBytes,
					sum(case when keyName = 'threadCount' then convert(bigint, keyValue) else null end) as threadCount

					from #runningProcesses

					group by ukey_server, ukey_run, processName
			) a
		join runs b on a.ukey_run = b.ukey
		join servers c on a.ukey_server = c.ukey
		order by c.serverName, a.processName, b.ymd

	select serverName, processName,
		avg(pageFileBytes) as pageFileBytes,
		avg(pageFileBytesPeak) as pageFileBytesPeak,
		avg(poolNonPagedBytes) as poolNonPagedBytes,
		avg(poolPagedBytes) as poolPagedBytes,
		avg(privateBytes) as privateBytes,
		avg(threadCount) as threadCount,
		max(ukey_run) as ukey_latestRun,
		convert(int, 0) as ukey_previousRun

		into #summaryData

		from #processSummary
		where processName <> 'Idle'
		group by serverName, processName

	update #summaryData
		set ukey_previousRun = b.ukey_run
		from #summaryData a
		join (
				select a.serverName, a.processName, max(ukey_run) as ukey_run
					from #processSummary a
					join #summaryData b on a.serverName = b.serverName
						and a.processName = b.processName
						and a.ukey_run < b.ukey_latestRun
					group by a.serverName, a.processName
			) b on a.serverName = b.serverName
				and a.processName = b.processName

	select
		identity(int) as ukey,
		a.serverName, a.processName,
		b.ymd as alertTime,
		a.pageFileBytes as averagePageFileBytes,
		b.pageFileBytes as actualPageFileBytes,
		c.pageFileBytes as previousPageFileBytes,

		a.pageFileBytesPeak as averagePageFileBytesPeak,
		b.pageFileBytesPeak as actualPageFileBytesPeak,
		c.pageFileBytesPeak as previousPageFileBytesPeak,

		a.poolNonPagedBytes as averagepoolNonPagedBytes,
		b.poolNonPagedBytes as actualpoolNonPagedBytes,
		c.poolNonPagedBytes as previousPoolNonPagedBytes,

		a.poolPagedBytes as averagepoolPagedBytes,
		b.poolPagedBytes as actualpoolPagedBytes,
		c.poolPagedBytes as previousPoolPagedBytes,

		a.privateBytes as averageprivateBytes,
		b.privateBytes as actualprivateBytes,
		c.privateBytes as previousPrivateBytes,

		a.threadCount as averagethreadCount,
		b.threadCount as actualthreadCount,
		c.threadCount as previousThreadCount

		into #results

		from #summaryData a
		left outer join #processSummary c on a.serverName = c.serverName
			and a.processName = c.processName
			and a.ukey_previousRun = c.ukey_run
		join #processSummary b on a.serverName = b.serverName
			and a.processName = b.processName
			and a.ukey_latestRun = b.ukey_run

			and (
				(b.pageFileBytes > isnull(c.pageFileBytes, 0) and abs(convert(decimal(15,2), (b.pageFileBytes - a.pageFileBytes)) / case when a.pageFileBytes = 0 then 1 else convert(decimal(15,2), a.pageFileBytes) end) > 0.10)
				or (b.pageFileBytesPeak > isnull(c.pageFileBytesPeak, 0) and abs(convert(decimal(15,2), (b.pageFileBytesPeak - a.pageFileBytesPeak)) / case when a.pageFileBytesPeak = 0 then 1 else convert(decimal(15,2), a.pageFileBytesPeak) end) > 0.10)
				or (b.poolNonPagedBytes > isnull(c.poolNonPagedBytes, 0) and abs(convert(decimal(15,2), (b.poolNonPagedBytes - a.poolNonPagedBytes)) / case when a.poolNonPagedBytes = 0 then 1 else convert(decimal(15,2), a.poolNonPagedBytes) end) > 0.10)
				or (b.poolPagedBytes > isnull(c.poolPagedBytes, 0) and abs(convert(decimal(15,2), (b.poolPagedBytes - a.poolPagedBytes)) / case when a.poolPagedBytes = 0 then 1 else convert(decimal(15,2), a.poolPagedBytes) end) > 0.10)
				or (b.privateBytes > isnull(c.privateBytes, 0) and abs(convert(decimal(15,2), (b.privateBytes - a.privateBytes)) / case when a.privateBytes = 0 then 1 else convert(decimal(15,2), a.privateBytes) end) > 0.10)
	--			or convert(decimal(15,2), (b.threadCount - a.threadCount)) / case when a.threadCount = 0 then 1 else convert(decimal(15,2), a.threadCount) end > 0.10
				)
		order by a.serverName, a.processName

	set @nThisUkey = 0

	while exists (select top 1 * from #results where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@cThisSubject = 'SQL Automated Alerts : Process resource warning for "' + isnull(processName, 'BAD NAME') + '" on ' + isnull(serverName, 'BAD SERVER') + ' at ' + convert(varchar(20), alertTime, 120) + '.',
			@cThisMessage =
	'Process Name           : ' + isnull(processName, 'BAD NAME') + char(13) +
	'Server                 : ' + isnull(serverName, 'BAD SERVER') + char(13) +
	'Poll Time              : ' + convert(varchar(20), alertTime, 120) + char(13) + char(13) +
	'                         ' + left('Current' + space(15), 15) + ' ' + left('Previous' + space(15), 15) + ' ' + left('Average' + space(15), 15) + ' ' + left('Change' + space(7), 7) + char(13) +
	'                         ' + replicate('=', 15) + ' ' + replicate('=', 15) + ' ' + replicate('=', 15) + ' ' + replicate('=', 7) + char(13) +
	'Page File Bytes        : ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPageFileBytes), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPageFileBytes), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagePageFileBytes), 15) + ' ' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualPageFileBytes - averagePageFileBytes) /
					case when averagePageFileBytes = 0 then 1 else convert(decimal(15,2), averagePageFileBytes) end
				)
			), 6) + '%' + char(13) +
	'Page File Bytes Peak   : ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPageFileBytesPeak), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPageFileBytesPeak), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagepageFileBytesPeak), 15) + ' ' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualPageFileBytesPeak - averagepageFileBytesPeak) /
					case when averagepageFileBytesPeak = 0 then 1 else convert(decimal(15,2), averagepageFileBytesPeak) end
				) * 100
			), 6) + '%' + char(13) +
	'Pool NonPaged Bytes    : ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPoolNonPagedBytes), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPoolNonPagedBytes), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagePoolNonPagedBytes), 15) + ' ' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualpoolNonPagedBytes - averagepoolNonPagedBytes) /
					case when averagepoolNonPagedBytes = 0 then 1 else convert(decimal(15,2), averagepoolNonPagedBytes) end
				) * 100
			), 6) + '%' + char(13) +
	'Pool Paged Bytes       : ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPoolPagedBytes), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPoolPagedBytes), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagePoolPagedBytes), 15) + ' ' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualpoolPagedBytes - averagepoolPagedBytes) /
					case when averagepoolPagedBytes = 0 then 1 else convert(decimal(15,2), averagepoolPagedBytes) end
				) * 100
			), 6) + '%' + char(13) +
	'Private Bytes          : ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualPrivateBytes), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousPrivateBytes), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averagePrivateBytes), 15) + ' ' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualprivateBytes - averageprivateBytes) /
					case when averageprivateBytes = 0 then 1 else convert(decimal(15,2), averageprivateBytes) end
				) * 100
			), 6) + '%' + char(13) +
	'Thread Count           : ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(actualThreadCount), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(previousThreadCount), 15) + ' ' +
		right(space(15) + notification.dbo.fn_returnFormattedInt(averageThreadCount), 15) + ' ' +
		right(space(6) + convert(varchar(6),
			convert(decimal(10,2),
				convert(decimal(15,2), actualthreadCount - averagethreadCount) /
					case when averagethreadCount = 0 then 1 else convert(decimal(15,2), averagethreadCount) end
				) * 100
			), 6) + '%'

			from #results
			where ukey > @nThisUkey
			order by ukey

		if (select count(*) from notification..messagesSent where ymd >= dateAdd(hour, -2, getDate()) and subject = @cThisSubject) = 0
			exec notification.dbo.pr_sendMessage '', 'DBA', @cThisSubject, @cThisMessage
	end

	drop table #runningProcesses
	drop table #processSummary
	drop table #results
	drop table #summaryData
end
GO
