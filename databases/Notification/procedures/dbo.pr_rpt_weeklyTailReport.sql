GO

-- select * from eventLog where computerName in (select serverName from dm_servers where ukey_group = 43)


ALTER procedure [dbo].[pr_rpt_weeklyTailReport]
as
begin
	set nocount on

	-- First, detail on the time and duration of outages in the last week
	declare @dStartDate dateTime
	declare @dEndDate dateTime
	declare @nThisUkey int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @dLatestViewData dateTime
	declare @cServerName varchar(500)
	declare @nCount int

	set @dStartDate = dateAdd(week, -1, getDate())

	create table #tailDetail (ukey int identity, serverName varchar(200), ukey_group int,
		eventDetail varchar(1000), startDate dateTime, endDate dateTime,
		isConnectivity bit, isReboot bit, isEventLog bit, isClusterFailure bit, isSQLError bit, groupName varchar(500))

	--*********************************************************************************************
	-- Servers unpingable
	--*********************************************************************************************
	create table #outages (serverName varchar(100), startDate dateTime, endDate dateTime, pingsDown int)

	select distinct serverName
		into #activeServers
		from pingLog (nolock)
		where isServerPingable = 0
--		where (isServerPingable = 0 or serverPingResults not like '%lost = 0%')

	set @dLatestViewData = (select max(ymd) from v_pingLog_all)

	insert into #outages (serverName, startDate, endDate)
	select a.serverName, ymd as outageStart, null as endDate
		from v_pingLog_all a (nolock)
		join #activeServers b on a.serverName = b.serverName
--		where (a.isServerPingable = 0 or a.serverPingResults not like '%lost = 0%')
		where a.isServerPingable = 0
			and a.ymd >= @dStartDate

	insert into #outages (serverName, startDate, endDate)
	select serverName, startDate, endDate
		from (
			select a.serverName, ymd as startDate, null as endDate, isServerPingable
				from pingLog a (nolock)
				join #activeServers b on a.serverName = b.serverName
				where a.ymd >= @dStartDate
					and a.ymd > @dLatestViewData
			) a
		where a.isServerPingable = 0

	create clustered index ix_tmp_outages on #outages (servername, startDate) with fillfactor = 100

	update #outages
		set endDate = b.endDate
		from #outages a
		join (
			select a.serverName, a.startDate,
				min(b.ymd) as endDate
				from #outages a
				join v_pingLog_all b (nolock) on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd >= @dStartDate
					and b.isServerPingable = 1
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate

	update #outages
		set endDate = b.endDate
		from #outages a
		join (
			select a.serverName, a.startDate,
				min(b.ymd) as endDate
				from #outages a
				join pingLog b (nolock) on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd >= @dStartDate
					and b.ymd >= @dLatestViewData
					and b.isServerPingable = 1
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate
		where a.endDate is null

	update #outages
		set pingsDown = b.pingsDown
		from #outages a
		join (
			select a.serverName, a.startDate, count(*) as pingsDown
				from #outages a
				join v_pingLog_all b on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd < a.endDate
					and b.isServerPingable = 0
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate

	update #outages
		set pingsDown = isnull(a.pingsDown, 0) + b.pingsDown
		from #outages a
		join (
			select a.serverName, a.startDate, count(*) as pingsDown
				from #outages a
				join pingLog b on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd < a.endDate
					and b.ymd >= @dLatestViewData
					and b.isServerPingable = 0
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate

	delete from #outages where pingsDown = 1

--	insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group, isConnectivity)
--	select c.groupName,
--		convert(varchar(20), count(distinct a.serverName)) + ' servers were down ' +
--			'for ' + convert(varchar(20), sum(pingsDown)) + ' PING attempts, ' +
--			'a total of ' + convert(varchar(20), sum(dateDiff(minute, startDate, endDate))) + ' server minutes ' +
--			'beginning this hour.',
--		min(startDate), max(endDate),
--		c.ukey,
--		1
--		from #outages a
--		join notification..dm_servers b on a.serverName = b.serverName
--		join notification..dm_serverGroups c on b.ukey_group = c.ukey
--		group by c.ukey, c.groupName, convert(varchar(10), a.startDate, 120), datePart(hour, a.startDate)
--		having count(distinct a.serverName) >= 5
--
--	delete #outages
--		from #outages a
--		join notification..dm_servers b on a.serverName = b.serverName
--		join (
--			select c.ukey as ukey_group, min(a.startDate) as startDate, max(a.endDate) as endDate
--				from #outages a
--				join notification..dm_servers b on a.serverName = b.serverName
--				join notification..dm_serverGroups c on b.ukey_group = c.ukey
--				group by c.ukey, convert(varchar(10), a.startDate, 120), datePart(hour, a.startDate)
--				having count(distinct a.serverName) >= 5
--			) d on b.ukey_group = d.ukey_group
--				and a.startDate >= d.startDate
--				and a.endDate <= d.endDate

	insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
	select a.serverName,
		case when dateDiff(minute, min(startDate), endDate) <= 1
			then 'PING check momentarily failed at '
			else 'Server unpingable at '
			end +
			convert(varchar(20), min(startDate), 120) +
			case
				when endDate is null then ', and is still OFFLINE'
--				when dateDiff(minute, min(startDate), endDate) <= 1 then ''
				when dateDiff(minute, min(startDate), endDate) < 60
					then ' for ' + convert(varchar(20), dateDiff(minute, min(startDate), endDate)) + ' minutes'
				else ' for ' + convert(varchar(20), convert(decimal(10,2), convert(decimal(10,2), dateDiff(minute, min(startDate), endDate))/60.00)) + ' hours(s)'
				end as eventDetail,
		min(a.startDate) as startDate,
		endDate as endDate,
		b.ukey_group
		from #outages a
		join notification..dm_servers b on a.serverName = b.serverName
		group by a.serverName, endDate, b.ukey_group
		having dateDiff(minute, min(startDate), endDate) > 2


	--*********************************************************************************************
	-- Other big issues
	--*********************************************************************************************

	create table #otherErrors (serverName varchar(100), subject varchar(500), ymd dateTime, ukey_group int)

	set @dLatestViewData = (select max(ymd) from v_notificationLog_all)

	insert into #otherErrors (serverName, subject, ymd, ukey_group)
	select
		a.serverName,
		case
			when subject like 'EventLog @%:%'
				then substring(subject, charindex(':', subject) + 5, 500)
			else left(subject, 500)
			end as subject,
		case
			when isEventLog = 1 and isdate(substring(message, charindex('@', message) + 2, 19) + '.000') = 1
				then convert(dateTime, substring(message, charindex('@', message) + 2, 19) + '.000')
				else ymd
			end as ymd,
		b.ukey_group
		from notificationLog  a (nolock)
		left outer join dm_servers b on a.serverName = b.serverName
		where severity = 1
			and a.serverName <> @@serverName
			and a.serverName <> (select top 1 settingValue from dm_settings where settingName = 'current machine name')
			and not (
				isConnectivity = 1
				and subject like '%is not accessible%'
				)
			and not subject like '%has been offline for more than%'
			and not subject like '%drive%is down to'
			and not subject like '%is failing to return%'
			and a.ymd >= @dStartDate
			and a.ymd > @dLatestViewData

	insert into #otherErrors (serverName, subject, ymd, ukey_group)
	select
		a.serverName,
		case
			when subject like 'EventLog @%:%'
				then substring(subject, charindex(':', subject) + 5, 500)
			else left(subject, 500)
			end as subject,
		case
			when isEventLog = 1 and isdate(substring(message, charindex('@', message) + 2, 19) + '.000') = 1
				then convert(dateTime, substring(message, charindex('@', message) + 2, 19) + '.000')
				else ymd
			end as ymd,
		b.ukey_group
		from v_notificationLog_all  a (nolock)
		left outer join dm_servers b on a.serverName = b.serverName
		where severity = 1
			and a.serverName <> @@serverName
			and a.serverName <> (select top 1 settingValue from dm_settings where settingName = 'current machine name')
			and not (
				isConnectivity = 1
				and subject like '%is not accessible%'
				)
--			and not (
--				isConnectivity = 1
--				and subject like '%is failing to return%'
--				)
			and not subject like '%has been offline for more than%'
			and not subject like '%drive%is down to'
			and not subject like '%is failing to return%'
			and a.ymd >= @dStartDate

	-- changes in state
	insert into #tailDetail (groupName, serverName, eventDetail, startDate, endDate)
	select d.category, d.keyName, a.currentState as oldState, a.ymd as startDate, b.ymd as endDate
		from (
			select a.ukey_stateKey, a.ymd, a.currentState, min(b.ukey) as ukey_stateChange
				from (
					select a.ukey_stateKey, a.ymd, a.currentState
						from stateLog a (nolock)
						join dm_stateValues b (nolock) on a.ukey_stateKey = b.ukey_stateKey
							and a.currentState = b.[state]
						where a.ymd >= @dStartDate
					) a
				left outer join stateLog b (nolock) on a.ukey_stateKey = b.ukey_stateKey
					and b.ymd > a.ymd
--					and a.currentState <> b.currentState
				group by a.ukey_stateKey, a.ymd, a.currentState
			) a
		join stateLog b (nolock) on a.ukey_stateChange = b.ukey
		join dm_stateValues c (nolock) on b.ukey_stateKey = c.ukey_stateKey
			and isnull(a.currentState, '') = isnull(c.state, '')
			and c.isGood = 0
--			-- must be bad for at least 2 minutes
--			and dateDiff(minute, a.ymd, b.ymd) > 2
		join dm_stateKeys d (nolock) on b.ukey_stateKey = d.ukey
		order by d.category, d.keyName, a.ymd

	insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
	select serverName,
		left(case
			when
				subject like '%cluster node%was removed%'
				or subject like '%cluster service%resource group%'
				or subject like '%node lost communication%'
				or subject like '%not ready to accept new%'
				or subject like '%cluster service brought the resource group%'
				or subject like '%cluster service%has failed%'
				or subject like '%removed from the active server%'

				or subject like '%interface for cluster node%'
				or subject like '%communication with cluster node%'
				or subject like '%joined the server cluster%'

				or subject like '%cluster node%failed a critical operation%'

				then 'SQL Restart/Cluster Failure'

			when
				subject like '%network link is down%'
				then 'Network link down'

			when
				subject like 'there are%'
				then 'Connections above threshold'

			when subject like '%jet database%' then 'JET Database Error'
			when subject like '%error is printed in terse mode%' then 'SQL Server has experienced a serious failure, and is unable to report errors'
			when subject like '%unable to reuse a session%connection pooling%' or subject like '%sql server failed%to spawn a thread to process a new login%' then 'SQL Server no longer accepting connections'
			when subject like '%temperature%' or subject like '%thermal%' or subject like '%too hot%' then 'Server temperature exceeded thresholds'
--			when subject like '%array controller%' or subject like '%degraded%' then 'Disk subsystem failure'
			when subject like '%drive%is down to'
				or subject like '%unable to write to the log%'
				or subject like '%drive%is down to%'
				or subject like '%low on disk space%'
				or subject like '%log for database%is full%'
				or subject like '%not enough space%'
				then 'Disk space below threshold'
			when subject like '%CPU load%' or subject like 'cpu load is%' then 'CPU utilization above threshold'

			when subject like '%event log service was%' or subject like '%initiated the restart%' or subject like '%system is shutting down%' then 'Rebooted'

			when subject like '%shutdown%was%unexpected%' or subject like '%unexpected%shutdown%' then 'Unexpected Shutdown'

			when subject like '%failed after%' or subject like '%failed at%' then left(subject, charindex('failed a', subject) +6)

			when subject like '%detailed check of%' or subject like '%counters out of tolerance%' then 'Server performance alert'

			when subject like '%could not find an entry%in database 2%' then 'TempDB index corruption'

			else subject
			end +
			case when count(*) > 1 then ' (' + convert(varchar(20), count(*))  + ')' else '' end, 1000) as eventDetail,
		min(ymd) as startDate,
		max(ymd) as endDate,
		ukey_group
		from #otherErrors
		group by serverName, ukey_group, convert(varchar(10), ymd, 120), --datePart(hour, ymd),
			case
			when
				subject like '%cluster node%was removed%'
				or subject like '%cluster service%resource group%'
				or subject like '%node lost communication%'
				or subject like '%not ready to accept new%'
				or subject like '%cluster service brought the resource group%'
				or subject like '%cluster service%has failed%'
				or subject like '%removed from the active server%'

				or subject like '%interface for cluster node%'
				or subject like '%communication with cluster node%'
				or subject like '%joined the server cluster%'

				or subject like '%cluster node%failed a critical operation%'

				then 'SQL Restart/Cluster Failure'

			when
				subject like '%network link is down%'
				then 'Network link down'

			when
				subject like 'there are%'
				then 'Connections above threshold'

			when subject like '%jet database%' then 'JET Database Error'
			when subject like '%error is printed in terse mode%' then 'SQL Server has experienced a serious failure, and is unable to report errors'
			when subject like '%unable to reuse a session%connection pooling%' or subject like '%sql server failed%to spawn a thread to process a new login%' then 'SQL Server no longer accepting connections'
			when subject like '%temperature%' or subject like '%thermal%' or subject like '%too hot%' then 'Server temperature exceeded thresholds'
--			when subject like '%array controller%' or subject like '%degraded%' then 'Disk subsystem failure'
			when subject like '%drive%is down to'
				or subject like '%unable to write to the log%'
				or subject like '%drive%is down to%'
				or subject like '%low on disk space%'
				or subject like '%log for database%is full%'
				or subject like '%not enough space%'
				then 'Disk space below threshold'
			when subject like '%CPU load%' or subject like 'cpu load is%' then 'CPU utilization above threshold'

			when subject like '%event log service was%' or subject like '%initiated the restart%' or subject like '%system is shutting down%' then 'Rebooted'

			when subject like '%shutdown%was%unexpected%' or subject like '%unexpected%shutdown%' then 'Unexpected Shutdown'

			when subject like '%failed after%' or subject like '%failed at%' then left(subject, charindex('failed a', subject) +6)

			when subject like '%detailed check of%' or subject like '%counters out of tolerance%' then 'Server performance alert'

			when subject like '%could not find an entry%in database 2%' then 'TempDB index corruption'

			else subject
			end

	-- this is covered by the stateLog checks
	delete from #tailDetail where eventDetail = 'disk space below threshold'

	if (select count(distinct ukey_group) from #tailDetail where eventDetail like '%temperature%') >= (select count(distinct ukey_group)/2 from dm_servers where isEnabled = 1)
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select 'ALL',
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + convert(varchar(20), count(distinct serverName)) + ' servers reported a thermal anomaly',
			min(startDate), max(endDate), -1
			from #tailDetail
			where eventDetail like '%temperature%' or eventDetail like '%thermal%'
			group by convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4

		delete from #tailDetail where (eventDetail like '%temperature%' or eventDetail like '%thermal%') and servername <> 'ALL'
	end

	if (select count(*) from #tailDetail where eventDetail like '%connections above threshold%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' connections were above defined thresholds',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%connections above threshold%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where (eventDetail like '%connections above threshold%') and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%temperature%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select 'ALL',
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + convert(varchar(20), count(distinct serverName)) + ' servers reported a thermal anomaly',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%temperature%' or eventDetail like '%thermal%'
			group by convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where (eventDetail like '%temperature%' or eventDetail like '%thermal%') and servername <> 'ALL'
	end

	if (select count(*) from #tailDetail where eventDetail like '%unable to report errors%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' recorded ' + convert(varchar(20), count(*)) + ' severe errors.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%unable to report errors%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where eventDetail like '%unable to report errors%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%jet database%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' recorded ' + convert(varchar(20), count(*)) + ' JET database errors.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%jet database%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where eventDetail like '%jet database%' and eventDetail not like '%between%'
	end

	if (
		select count(*)
			from #tailDetail
			where eventDetail like '%insufficient system memory to run this query%'
				or eventDetail like '%sqsrvres%'
				or eventDetail like '%insufficient memory%'
				or eventDetail like '%sql%assertion%'
				or eventDetail like '%memory allocation%'
		) >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' recorded ' + convert(varchar(20), count(*)) + ' severe errors.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%insufficient system memory to run this query%'
				or eventDetail like '%sqsrvres%'
				or eventDetail like '%sql%assertion%'
				or eventDetail like '%insufficient memory%'
				or eventDetail like '%memory allocation%'
			group by serverName, convert(varchar(10), startDate, 120), ukey_group

		delete from #tailDetail where (eventDetail like '%insufficient system memory to run this query%'
				or eventDetail like '%sqsrvres%'
				or eventDetail like '%sql%assertion%'
				or eventDetail like '%insufficient memory%'
				or eventDetail like '%memory allocation%')
			and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%is not accessible%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' was inaccessible ' + convert(varchar(20), count(*)) + ' times.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%is not accessible%'
			group by serverName, convert(varchar(10), startDate, 120), ukey_group

		delete from #tailDetail where eventDetail like '%is not accessible%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%no longer accepting connections%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' rejected at least ' + convert(varchar(20), count(*)) + ' connections.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%no longer accepting connections%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where eventDetail like '%no longer accepting connections%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%rebooted%') >= 20
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' rebooted at least once.',
			min(startDate), max(endDate), ukey_group
			from #tailDetail
			where eventDetail like '%rebooted%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4, ukey_group

		delete from #tailDetail where eventDetail like '%rebooted%' and eventDetail not like '%between%'
	end


	delete from #tailDetail where eventDetail like '%url%is unavailable%'
	delete from #tailDetail where eventDetail like '%server performance%'
	delete from #tailDetail where eventDetail like '%rjohnson%'
--	delete from #tailDetail where eventDetail like '%cpu utilization%'
	delete from #tailDetail where eventDetail like '%applicationserveradministrationservicejob%'
	delete from #tailDetail where eventDetail like '%sql automated alerts%'
	delete from #tailDetail where eventDetail is null

	set @nThisUkey = 0
	while exists (select top 1 ukey from #tailDetail where (eventDetail like '%sql restart%' or eventDetail like '%rebooted%') and ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@dStartDate = startDate,
			@cServerName = serverName,
			@dEndDate = endDate
			from #tailDetail
			where (eventDetail like '%sql restart%' or eventDetail like '%rebooted%')
				and ukey > @nThisUkey
			order by ukey

		set @nCount = (
			select count(*)
				from #tailDetail
				where eventDetail like '%login failure%'
					and startDate >= dateAdd(minute, -2, @dStartDate)
					and startDate <= dateAdd(minute, 2, @dEndDate)
					and serverName = @cServerName
			)

print 'Found ' + convert(varchar(20), @nCount) + ' login failures'

		if @nCount > 1
		begin
			delete from #tailDetail
				where eventDetail like '%login failure%'
					and startDate >= dateAdd(minute, -2, @dStartDate)
					and startDate <= dateAdd(minute, 2, @dEndDate)
					and serverName = @cServerName

			insert into #tailDetail (groupName, serverName, eventDetail, startDate, endDate, ukey_group)
			select groupName, serverName,
				convert(varchar(20), @nCount) + ' logins failed during restart' as eventDetail, startDate, endDate, ukey_group
				from #tailDetail
				where ukey = @nThisUkey
		end


		delete from #tailDetail
			where (
					eventDetail like '%network link down%'
					or eventDetail like '%server temperature%'
					or eventDetail like '%server%is not accessible%'
					or eventDetail like '%raid%successful%'
					)
				and startDate >= dateAdd(minute, -2, @dStartDate)
				and startDate <= dateAdd(minute, 2, @dEndDate)
				and serverName = @cServerName

	end

	delete from #tailDetail where eventDetail like '%failed to make contact%'

	--***********************************************************************************************************
	-- Results
	--***********************************************************************************************************
--	set @dStartDate = dateAdd(week, -2, getDate())

	select distinct
		case when isnull(a.groupName, '') <> '' then a.groupName else isnull(c.groupName, 'Other') end as groupName,
		isnull(isnull(b.friendlyName, b.serverName), a.serverName ) as serverName, eventDetail, startDate, endDate
		from #tailDetail a
		left outer join dm_servers b on a.serverName = b.serverName
		left outer join dm_serverGroups c on a.ukey_group = c.ukey
		where startDate >= @dStartDate
			and a.serverName not like '%dev%'
--			and (
--				c.ukey is null
--				or c.isProduction = 1
--				or c.groupName like '%uat%'
--				)
--			and not startDate between '2008-07-11 17:00:00.000' and '2008-07-13 23:59:59.000'
			--and isnull(b.serverName, '') not in ('sis-gtid1', 'labmsproj01')
		order by case when isnull(a.groupName, '') <> '' then a.groupName else isnull(c.groupName, 'Other') end,
			startDate, isnull(isnull(b.friendlyName, b.serverName), a.serverName )

	drop table #outages
	drop table #activeServers
	drop table #tailDetail
	drop table #otherErrors


end
