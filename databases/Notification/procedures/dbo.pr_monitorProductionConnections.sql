CREATE procedure [dbo].[pr_monitorProductionConnections]
as
begin
	set nocount on

	declare @cThisMessage varchar(4000)
	declare @cThisSubject varchar(500)
	declare @nUkey int
	declare @cThisServerName varchar(100)
	declare @cSQLString nvarchar(4000)
	declare @nNumMinutes int

	declare @dStartDate dateTime
	declare @dEndDate dateTime

	declare @dStartDate1 dateTime
	declare @dEndDate1 dateTime

	declare @dStartDate2 dateTime
	declare @dEndDate2 dateTime

	declare @dStartDate3 dateTime
	declare @dEndDate3 dateTime

	set @nNumMinutes = 90

	set @dEndDate = getDate()
	set @dStartDate = dateAdd(minute, -@nNumMinutes, @dEndDate)

	set @dEndDate1 = dateAdd(week, -1, @dEndDate)
	set @dStartDate1 = dateAdd(minute, -@nNumMinutes, @dEndDate1)

	set @dEndDate2 = dateAdd(week, -1, @dEndDate1)
	set @dStartDate2 = dateAdd(minute, -@nNumMinutes, @dEndDate2)

	set @dEndDate3 = dateAdd(week, -1, @dEndDate2)
	set @dStartDate3 = dateAdd(minute, -@nNumMinutes, @dEndDate3)

	set @cThisServerName = (select top 1 settingValue from dm_settings where settingName = 'current machine name')

	select
		serverName, ymd,
		convert(decimal(10,2), convert(decimal(10,2), a.numActiveConnections) / convert(decimal(10,2), a.numPolls)) as numActiveConnections,
		isnull(a.numPolls, 0) as numPolls,

		convert(decimal(10,2), convert(decimal(10,2), isnull(a.numWaitingConnections_oledb, 0)) / convert(decimal(10,2), a.numPolls)) as numWaitingConnections_oledb,
		convert(decimal(10,2), convert(decimal(10,2), isnull(a.secondsElapsed_avg_oledb, 0)) / convert(decimal(10,2), a.numPolls)) as secondsElapsed_avg_oledb,
		convert(decimal(10,2), convert(decimal(10,2), isnull(a.secondsElapsed_max_oledb, 0)) / convert(decimal(10,2), a.numPolls)) as secondsElapsed_max_oledb,

		convert(decimal(10,2), convert(decimal(10,2), isnull(a.numWaitingConnections, 0)) / convert(decimal(10,2), a.numPolls)) as numWaitingConnections,
		convert(decimal(10,2), convert(decimal(10,2), isnull(a.secondsElapsed_avg, 0)) / convert(decimal(10,2), a.numPolls)) as secondsElapsed_avg,
		convert(decimal(10,2), convert(decimal(10,2), isnull(a.secondsElapsed_max, 0)) / convert(decimal(10,2), a.numPolls)) as secondsElapsed_max

		into #current
		from (
			select
				serverName,
				max(ymd) as ymd,
				count(*) as numActiveConnections,
				count(distinct convert(varchar(16), ymd, 120)) as numPolls,

				avg(case when lastWaitType = 'oledb' then dateDiff(second, lastBatchTime, ymd) else null end) as secondsElapsed_avg_oledb,
				max(case when lastWaitType = 'oledb' then dateDiff(second, lastBatchTime, ymd) else null end) as secondsElapsed_max_oledb,
				sum(case when lastWaitType = 'oledb' then 1 else 0 end) as numWaitingConnections_oledb,

				avg(case when lastWaitType <> 'oledb' then dateDiff(second, lastBatchTime, ymd) else null end) as secondsElapsed_avg,
				max(case when lastWaitType <> 'oledb' then dateDiff(second, lastBatchTime, ymd) else null end) as secondsElapsed_max,
				sum(case when lastWaitType <> 'oledb' then 1 else 0 end) as numWaitingConnections

				from processLog (nolock)
				where serverName in (select serverName from dm_servers (nolock) where ukey_group in (select ukey from dm_serverGroups (nolock) where isProduction = 1 ))
					and ymd between @dStartDate and @dEndDate
					and lastBatchTime between @dStartDate and @dEndDate
					and spid > 50
					and programName not in ('SQLAgent - Job invocation engine', 'SQLAgent - Generic Refresher')
					and programName not like '%repl%'
					and hostName <> @cThisServerName
					and command <> 'awaiting command'
				group by serverName
			) a

	-- create the table
	select top 0 * into #historical from #current

	set @cSQLString = '
	select
		serverName, ymd,
		convert(decimal(10,2), convert(decimal(10,2), a.numActiveConnections) / convert(decimal(10,2), a.numPolls)) as numActiveConnections,
		isnull(a.numPolls, 0) as numPolls,

		convert(decimal(10,2), convert(decimal(10,2), isnull(a.numWaitingConnections_oledb, 0)) / convert(decimal(10,2), a.numPolls)) as numWaitingConnections_oledb,
		convert(decimal(10,2), convert(decimal(10,2), isnull(a.secondsElapsed_avg_oledb, 0)) / convert(decimal(10,2), a.numPolls)) as secondsElapsed_avg_oledb,
		convert(decimal(10,2), convert(decimal(10,2), isnull(a.secondsElapsed_max_oledb, 0)) / convert(decimal(10,2), a.numPolls)) as secondsElapsed_max_oledb,

		convert(decimal(10,2), convert(decimal(10,2), isnull(a.numWaitingConnections, 0)) / convert(decimal(10,2), a.numPolls)) as numWaitingConnections,
		convert(decimal(10,2), convert(decimal(10,2), isnull(a.secondsElapsed_avg, 0)) / convert(decimal(10,2), a.numPolls)) as secondsElapsed_avg,
		convert(decimal(10,2), convert(decimal(10,2), isnull(a.secondsElapsed_max, 0)) / convert(decimal(10,2), a.numPolls)) as secondsElapsed_max
		from (
			select
				serverName,
				max(ymd) as ymd,
				count(*) as numActiveConnections,
				count(distinct convert(varchar(16), ymd, 120)) as numPolls,

				avg(case when lastWaitType = ''oledb'' then dateDiff(second, lastBatchTime, ymd) else null end) as secondsElapsed_avg_oledb,
				max(case when lastWaitType = ''oledb'' then dateDiff(second, lastBatchTime, ymd) else null end) as secondsElapsed_max_oledb,
				sum(case when lastWaitType = ''oledb'' then 1 else 0 end) as numWaitingConnections_oledb,

				avg(case when lastWaitType <> ''oledb'' then dateDiff(second, lastBatchTime, ymd) else null end) as secondsElapsed_avg,
				max(case when lastWaitType <> ''oledb'' then dateDiff(second, lastBatchTime, ymd) else null end) as secondsElapsed_max,
				sum(case when lastWaitType <> ''oledb'' then 1 else 0 end) as numWaitingConnections

				from v_processLog_all (nolock)
				where serverName in (select serverName from dm_servers (nolock) where ukey_group in (select ukey from dm_serverGroups (nolock) where isProduction = 1 ))
					and (
						(ymd between ''' + convert(varchar(20), @dStartDate1, 120) + ''' and ''' + convert(varchar(20), @dEndDate1, 120) + '''
							and lastBatchTime between ''' + convert(varchar(20), @dStartDate1, 120) + ''' and ''' + convert(varchar(20), @dEndDate1, 120) + '''
							)
						or (ymd between ''' + convert(varchar(20), @dStartDate2, 120) + ''' and ''' + convert(varchar(20), @dEndDate2, 120) + '''
							and lastBatchTime between ''' + convert(varchar(20), @dStartDate2, 120) + ''' and ''' + convert(varchar(20), @dEndDate2, 120) + '''
							)
						or (ymd between ''' + convert(varchar(20), @dStartDate3, 120) + ''' and ''' + convert(varchar(20), @dEndDate3, 120) + '''
							and lastBatchTime between ''' + convert(varchar(20), @dStartDate3, 120) + ''' and ''' + convert(varchar(20), @dEndDate3, 120) + '''
							)
						)
					and spid > 50
					and programName not in (''SQLAgent - Job invocation engine'', ''SQLAgent - Generic Refresher'')
					and programName not like ''%repl%''
					and hostName <> ''' + @cThisServerName + '''
					and command <> ''awaiting command''
				group by serverName
			) a'

	insert into #historical
	exec sp_executeSQL @cSQLString

	select
		a.serverName, a.ymd,

		a.numActiveConnections as numActiveConnections_now, b.numActiveConnections as numActiveConnections_hist,
		case when b.numActiveConnections <> 0
			then convert(int, (
						convert(decimal(10,2), a.numActiveConnections) / convert(decimal(10,2), b.numActiveConnections)
					) * 100
				)
			else 0
			end as numActiveConnections_delta,

		a.numWaitingConnections_oledb as numWaitingConnections_oledb_now, b.numWaitingConnections_oledb as numWaitingConnections_oledb_hist,
		case when b.numWaitingConnections_oledb <> 0
			then convert(int, (
						convert(decimal(10,2), a.numWaitingConnections_oledb) / convert(decimal(10,2), b.numWaitingConnections_oledb)
					) * 100
				)
			else 0
			end as numWaitingConnections_oledb_delta,

		a.secondsElapsed_avg_oledb as secondsElaps
ed_avg_oledb_now, b.secondsElapsed_avg_oledb as secondsElapsed_avg_oledb_hist,
		case when b.secondsElapsed_avg_oledb <> 0
			then convert(int, (
						convert(decimal(10,2), a.secondsElapsed_avg_oledb) / convert(decimal(10,2), b.secondsElapsed_avg_oledb)
					) * 100
				)
			else 0
			end as secondsElapsed_avg_oledb_delta,

		a.secondsElapsed_max_oledb as secondsElapsed_max_oledb_now, b.secondsElapsed_max_oledb as secondsElapsed_max_oledb_hist,
		case when b.secondsElapsed_max_oledb <> 0
			then convert(int, (
						convert(decimal(10,2), a.secondsElapsed_max_oledb) / convert(decimal(10,2), b.secondsElapsed_max_oledb)
					) * 100
				)
			else 0
			end as secondsElapsed_max_oledb_delta,

		a.numWaitingConnections as numWaitingConnections_now, b.numWaitingConnections as numWaitingConnections_hist,
		case when b.numWaitingConnections <> 0
			then convert(int, (
						convert(decimal(10,2), a.numWaitingConnections) / convert(decimal(10,2), b.numWaitingConnections)
					) * 100
				)
			else 0
			end as numWaitingConnections_delta,

		a.secondsElapsed_avg as secondsElapsed_avg_now, b.secondsElapsed_avg as secondsElapsed_avg_hist,
		case when b.secondsElapsed_avg <> 0
			then convert(int, (
						convert(decimal(10,2), a.secondsElapsed_avg) / convert(decimal(10,2), b.secondsElapsed_avg)
					) * 100
				)
			else 0
			end as secondsElapsed_avg_delta,

		a.secondsElapsed_max as secondsElapsed_max_now, b.secondsElapsed_max as secondsElapsed_max_hist,
		case when b.secondsElapsed_max <> 0
			then convert(int, (
						convert(decimal(10,2), a.secondsElapsed_max) / convert(decimal(10,2), b.secondsElapsed_max)
					) * 100
				)
			else 0
			end as secondsElapsed_max_delta,

		identity(int) as ukey

		into #results

		from #current a
		join #historical b on a.serverName = b.serverName
		order by a.serverName

	set @cThisServerName = ''

	while exists (
		select top 1 serverName
			from dm_servers (nolock)
			where ukey_group in (select ukey from dm_serverGroups where isProduction =1 )
				and serverName > @cThisServerName
				and detailedCheck = 1
		)
	begin
		select top 1 @cThisServerName = serverName
			from dm_servers	 (nolock)
			where ukey_group in (
					select ukey
						from dm_serverGroups
						where isProduction = 1
					)
				and serverName > @cThisServerName
				and detailedCheck = 1
			order by serverName

		set @cThisMessage = ''

		select
			@cThisSubject = 'Connections to ' + @cThisServerName + ' out of tolerance at ' + right(convert(varchar(19), ymd, 120), 8) + '.',
			@cThisMessage = 'Connections between ' + right(convert(varchar(19), @dStartDate, 120), 8) + ' and ' + right(convert(varchar(19), ymd, 120), 8) + '.' + char(13) + char(13) +
				left('Measure' + space(30), 30) + ' ' +
				left('Now' + space(6), 6) + ' ' +
				left('Avg' + space(6), 6) + ' ' +
				left('Relative' + space(8), 8) + char(13) +

				replicate('=', 30) + ' ' +
				replicate('=', 6) + ' ' +
				replicate('=', 6) + ' ' +
				replicate('=', 8) + ' ' + char(13) +

				left('Number of active connections' + space(30), 30) + ' ' +
				right(space(4) + convert(varchar(20), numActiveConnections_now), 6) + ' ' +
				right(space(4) + convert(varchar(20), numActiveConnections_hist), 6) + ' ' +
				right(space(8) + convert(varchar(20), numActiveConnections_delta), 7) + '%' + char(13) +

				left('OLEDB waiting connections' + space(30), 30) + ' ' +
				right(space(3) + convert(varchar(20), numWaitingConnections_oledb_now), 6) + ' ' +
				right(space(3) + convert(varchar(20), numWaitingConnections_oledb_hist), 6) + ' ' +
				right(space(7) + convert(varchar(20), numWaitingConnections_oledb_delta), 7) + '%' + char(13) +

				left('OLEDB waiting seconds (avg)' + space(30), 30) + ' ' +
				right(space(3) + convert(varchar(20), secondsElapsed_avg_oledb_now), 6) + ' ' +
				right(space(3) + convert(varchar(20), secondsElapsed_avg_oledb_hist), 6) + ' ' +
				right(space(7) + convert(varchar(20), secondsElapsed_avg_oledb_delta), 7) + '%' + char(13) +

				left('OLEDB waiting seconds (max)' + space(30), 30) + ' ' +
				right(space(3) + convert(varchar(20), secondsElapsed_max_oledb_now), 6) + ' ' +
				right(space(3) + convert(varchar(20), secondsElapsed_max_oledb_hist), 6) + ' ' +
				right(space(7) + convert(varchar(20), secondsElapsed_max_oledb_delta), 7) + '%' + char(13) +

				left('Waiting connections' + space(30), 30) + ' ' +
				right(space(3) + convert(varchar(20), numWaitingConnections_now), 6) + ' ' +
				right(space(3) + convert(varchar(20), numWaitingConnections_hist), 6) + ' ' +
				right(space(7) + convert(varchar(20), numWaitingConnections_delta), 7) + '%' + char(13) +

				left('Waiting seconds (avg)' + space(30), 30) + ' ' +
				right(space(3) + convert(varchar(20), secondsElapsed_avg_now), 6) + ' ' +
				right(space(3) + convert(varchar(20), secondsElapsed_avg_hist), 6) + ' ' +
				right(space(7) + convert(varchar(20), secondsElapsed_avg_delta), 7) + '%' + char(13) +

				left('Waiting seconds (max)' + space(30), 30) + ' ' +
				right(space(3) + convert(varchar(20), secondsElapsed_max_now), 6) + ' ' +
				right(space(3) + convert(varchar(20), secondsElapsed_max_hist), 6) + ' ' +
				right(space(7) + convert(varchar(20), secondsElapsed_max_delta), 7) + '%'

			from #results

			where
				(
					numActiveConnections_delta >= 300
					or numActiveConnections_delta <= 25
					or numWaitingConnections_delta >= 300
					or numWaitingConnections_oledb_delta >= 300
					)
				and serverName = @cThisServerName

		if @@rowcount > 0
		begin
			print @cThisServerName
			print @cThisSubject
			print @cThisMessage

			insert into notificationLog_stage (serverName, subject, message, severity) values (@cThisServerName, @cThisSubject, @cThisMessage, 2)
		end

	end

	drop table #current
	drop table #historical
	drop table #results

end


GO
