alter procedure [dbo].[pr_rpt_outageReport]
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

	create table #tailDetail (ukey int identity, serverName varchar(200), eventDetail varchar(8000), startDate dateTime, endDate dateTime)

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select serverName, message , ymd, null
		from notification.dbo.notificationLog (nolock)
		where severity in (1,2)
			and not (severity = 2 and (serverName like '%dev%' or serverName like '%uat%'))
			and subject not like '%status report%'
			and message not like '%cannot obtain the schema%'
			and not isLongRunningProcess = 1
			and not (subject like 'error%' and serverName = 'Portal Watcher')
			and not subject like '%provisioning error%'
			and not (serverName = 'heatsqllive' and isBlocking = 1)
			and not subject like '%report server database is an invalid version%'
			and not subject like '%virusscan%update failed%'
			and ymd >= @dStartDate
		order by ymd desc


	--*********************************************************************************************
	-- Servers unpingable
	--*********************************************************************************************
	create table #outages (serverName varchar(100), startDate dateTime, endDate dateTime, pingsDown int)

	select distinct serverName
		into #activeServers
		from notification.dbo.pingLog (nolock)
		where isServerPingable = 0
--		where (isServerPingable = 0 or serverPingResults not like '%lost = 0%')

	set @dLatestViewData = (select max(ymd) from notification.dbo.v_pingLog_all)

	insert into #outages (serverName, startDate, endDate)
	select a.serverName, ymd as outageStart, null as endDate
		from notification.dbo.v_pingLog_all a (nolock)
		join #activeServers b on a.serverName = b.serverName
--		where (a.isServerPingable = 0 or a.serverPingResults not like '%lost = 0%')
		where a.isServerPingable = 0
			and a.ymd >= @dStartDate

	insert into #outages (serverName, startDate, endDate)
	select serverName, startDate, endDate
		from (
			select a.serverName, ymd as startDate, null as endDate, isServerPingable
				from notification.dbo.pingLog a (nolock)
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
				join notification.dbo.v_pingLog_all b (nolock) on a.serverName = b.serverName
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
				join notification.dbo.pingLog b (nolock) on a.serverName = b.serverName
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
				join notification.dbo.v_pingLog_all b on a.serverName = b.serverName
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
				join notification.dbo.pingLog b on a.serverName = b.serverName
					and b.ymd >= a.startDate
					and b.ymd < a.endDate
					and b.ymd >= @dLatestViewData
					and b.isServerPingable = 0
				group by a.serverName, a.startDate
			) b on a.serverName = b.serverName
				and a.startDate = b.startDate

	delete from #outages where pingsDown = 1

	--insert into #tailDetail (serverName, eventDetail, startDate, endDate, ukey_group, isConnectivity)
	--select c.groupName,
	--	convert(varchar(20), count(distinct a.serverName)) + ' servers were down ' +
	--		'for ' + convert(varchar(20), sum(pingsDown)) + ' PING attempts, ' +
	--		'a total of ' + convert(varchar(20), sum(dateDiff(minute, startDate, endDate))) + ' server minutes ' +
	--		'beginning this hour.',
	--	min(startDate), max(endDate),
	--	c.ukey,
	--	1
	--	from #outages a
	--	join notification..dm_servers b on a.serverName = b.serverName
	--	join notification..dm_serverGroups c on b.ukey_group = c.ukey
	--	group by c.ukey, c.groupName, convert(varchar(10), a.startDate, 120), datePart(hour, a.startDate)
	--	having count(distinct a.serverName) >= 5

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

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
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
		endDate as endDate
		from #outages a
		join notification..dm_servers b on a.serverName = b.serverName
		group by a.serverName, endDate
		having dateDiff(minute, min(startDate), endDate) > 2



	-- changes in state
	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select d.keyName, a.currentState as oldState, a.ymd as startDate, b.ymd as endDate
		from (
			select a.ukey_stateKey, a.ymd, a.currentState, min(b.ukey) as ukey_stateChange
				from (
					select a.ukey_stateKey, a.ymd, a.currentState
						from notification.dbo.stateLog a (nolock)
						join notification.dbo.dm_stateValues b (nolock) on a.ukey_stateKey = b.ukey_stateKey
							and a.currentState = b.[state]
						where a.ymd >= @dStartDate
					) a
				left outer join notification.dbo.stateLog b (nolock) on a.ukey_stateKey = b.ukey_stateKey
					and b.ymd > a.ymd
--					and a.currentState <> b.currentState
				group by a.ukey_stateKey, a.ymd, a.currentState
			) a
		join notification.dbo.stateLog b (nolock) on a.ukey_stateChange = b.ukey
		join notification.dbo.dm_stateValues c (nolock) on b.ukey_stateKey = c.ukey_stateKey
			and isnull(a.currentState, '') = isnull(c.state, '')
			and c.isGood = 0
--			-- must be bad for at least 2 minutes
--			and dateDiff(minute, a.ymd, b.ymd) > 2
		join notification.dbo.dm_stateKeys d (nolock) on b.ukey_stateKey = d.ukey
		order by d.category, d.keyName, a.ymd


	-- this is covered by the stateLog checks
	delete from #tailDetail where eventDetail = 'disk space below threshold'

	if (select count(*) from #tailDetail where eventDetail like '%connections above threshold%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' connections were above defined thresholds',
			min(startDate), max(endDate)
			from #tailDetail
			where eventDetail like '%connections above threshold%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4

		delete from #tailDetail where (eventDetail like '%connections above threshold%') and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%temperature%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate)
		select 'ALL',
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + convert(varchar(20), count(distinct serverName)) + ' servers reported a thermal anomaly',
			min(startDate), max(endDate)
			from #tailDetail
			where eventDetail like '%temperature%' or eventDetail like '%thermal%'
			group by convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4

		delete from #tailDetail where (eventDetail like '%temperature%' or eventDetail like '%thermal%') and servername <> 'ALL'
	end

	if (select count(*) from #tailDetail where eventDetail like '%unable to report errors%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' recorded ' + convert(varchar(20), count(*)) + ' severe errors.',
			min(startDate), max(endDate)
			from #tailDetail
			where eventDetail like '%unable to report errors%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4

		delete from #tailDetail where eventDetail like '%unable to report errors%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%jet database%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' recorded ' + convert(varchar(20), count(*)) + ' JET database errors.',
			min(startDate), max(endDate)
			from #tailDetail
			where eventDetail like '%jet database%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4

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
		insert into #tailDetail (serverName, eventDetail, startDate, endDate)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' recorded ' + convert(varchar(20), count(*)) + ' severe errors.',
			min(startDate), max(endDate)
			from #tailDetail
			where eventDetail like '%insufficient system memory to run this query%'
				or eventDetail like '%sqsrvres%'
				or eventDetail like '%sql%assertion%'
				or eventDetail like '%insufficient memory%'
				or eventDetail like '%memory allocation%'
			group by serverName, convert(varchar(10), startDate, 120)

		delete from #tailDetail where (eventDetail like '%insufficient system memory to run this query%'
				or eventDetail like '%sqsrvres%'
				or eventDetail like '%sql%assertion%'
				or eventDetail like '%insufficient memory%'
				or eventDetail like '%memory allocation%')
			and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%is not accessible%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' was inaccessible ' + convert(varchar(20), count(*)) + ' times.',
			min(startDate), max(endDate)
			from #tailDetail
			where eventDetail like '%is not accessible%'
			group by serverName, convert(varchar(10), startDate, 120)

		delete from #tailDetail where eventDetail like '%is not accessible%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%no longer accepting connections%') >= 5
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' rejected at least ' + convert(varchar(20), count(*)) + ' connections.',
			min(startDate), max(endDate)
			from #tailDetail
			where eventDetail like '%no longer accepting connections%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4

		delete from #tailDetail where eventDetail like '%no longer accepting connections%' and eventDetail not like '%between%'
	end

	if (select count(*) from #tailDetail where eventDetail like '%rebooted%') >= 20
	begin
		insert into #tailDetail (serverName, eventDetail, startDate, endDate)
		select serverName,
			'Between ' + convert(varchar(20), min(startDate), 120) + ' and ' + convert(varchar(20), max(endDate), 120) + ' ' + serverName + ' rebooted at least once.',
			min(startDate), max(endDate)
			from #tailDetail
			where eventDetail like '%rebooted%'
			group by serverName, convert(varchar(10), startDate, 120), datePart(hour, startDate) / 4

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
		isnull(isnull(b.friendlyName, b.serverName), a.serverName ) as serverName,
		replace(replace(replace(replace(eventDetail, char(13), '<br>'), char(10), '<br>'), '<br><br>', '<br>'), '<br><br>', '<br>') as eventDetail,
		startDate, endDate
		from #tailDetail a
		left outer join notification.dbo.dm_servers b on a.serverName = b.serverName
		where startDate >= @dStartDate
			and a.serverName not like '%dev%'
--			and (
--				c.ukey is null
--				or c.isProduction = 1
--				or c.groupName like '%uat%'
--				)
--			and not startDate between '2008-07-11 17:00:00.000' and '2008-07-13 23:59:59.000'
			--and isnull(b.serverName, '') not in ('sis-gtid1', 'labmsproj01')
		order by startDate, isnull(isnull(b.friendlyName, b.serverName), a.serverName )

	drop table #outages
	drop table #activeServers
	drop table #tailDetail



end
