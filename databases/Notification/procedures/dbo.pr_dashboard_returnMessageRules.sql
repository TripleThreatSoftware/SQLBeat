IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_dashboard_returnMessageRules]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'--select * from messageRules
-- update messageRules set severity = 0

-- exec pr_dashboard_returnMessageRules ''cole''

CREATE procedure [pr_dashboard_returnMessageRules] (@cUserName varchar(100))
as
begin
	select ukey,
		case when right(ruleDescription, 2) in ('', '', '': '') then left(ruleDescription, len(ruleDescription) - 1) else ruleDescription end as ruleDescription,
		case when right(sourceType, 2) = '', '' then left(sourceType, len(sourceType) - 1) else sourceType end as sourceType
		from (
			select
				a.ukey,
				isnull(isnull(serverEquals, serverLike), ''ALL'') + '' : '' +
					case when sendMessage = 1 then ''SEND : ''
						when doNotSendMessage = 1 then ''DO NOT : ''
						else '''' end +
					isnull(b.groupName + '' : '', '''') +
					isnull(subjectLike + '' : '', '''') +
					isnull(messageLike + '' : '', '''') +
--					case when isnull(isJobFailure, 0) = 1 then ''Job Failure, '' else '''' end +
--					case when isnull(isLongRunningJob, 0) = 1 then ''Long Running Job, '' else '''' end +
--					case when isnull(isBlocking, 0) = 1 then ''Blocking, '' else '''' end +
--					case when isnull(isLongRunningProcess, 0) = 1 then ''Long Running, '' else '''' end +
--					case when isnull(isDriveSpace, 0) = 1 then ''Drive Space, '' else '''' end +
--					case when isnull(isLogSize, 0) = 1 then ''Log Size, '' else '''' end +
--					case when isnull(isEventLog, 0) = 1 then ''Event Log, '' else '''' end +
--					case when isnull(isService, 0) = 1 then ''Service, '' else '''' end +
--					case when isnull(isConnectivity, 0) = 1 then ''Connectivity, '' else '''' end +
--					case when isnull(isConfiguration, 0) = 1 then ''Configuration, '' else '''' end +
--					case when isnull(isInstalledSoftware, 0) = 1 then ''Software, '' else '''' end +
--					case when isnull(isFulfillment, 0) = 1 then ''Fulfillment, '' else '''' end +
--					case when isnull(isMonitorMessage, 0) = 1 then ''Monitoring, '' else '''' end +
					case
						when isnull(businessHours, 0) = 1 and isnull(offHours, 0) = 1 then ''''
						when isnull(businessHours, 0) = 1 and isnull(offHours, 0) = 0 then ''Business Hours, ''
						when isnull(businessHours, 0) = 0 and isnull(offHours, 0) = 1 then ''Off Hours, ''
						else ''''
						end
					as ruleDescription,

					case when isnull(isJobFailure, 0) = 1 then ''Job Failure, '' else '''' end +
						case when isnull(isLongRunningJob, 0) = 1 then ''Long Running Job, '' else '''' end +
						case when isnull(isBlocking, 0) = 1 then ''Blocking, '' else '''' end +
						case when isnull(isLongRunningProcess, 0) = 1 then ''Long Running, '' else '''' end +
						case when isnull(isDriveSpace, 0) = 1 then ''Drive Space, '' else '''' end +
						case when isnull(isLogSize, 0) = 1 then ''Log Size, '' else '''' end +
						case when isnull(isEventLog, 0) = 1 then ''Event Log, '' else '''' end +
						case when isnull(isService, 0) = 1 then ''Service, '' else '''' end +
						case when isnull(isConnectivity, 0) = 1 then ''Connectivity, '' else '''' end +
						case when isnull(isConfiguration, 0) = 1 then ''Configuration, '' else '''' end +
						case when isnull(isInstalledSoftware, 0) = 1 then ''Software, '' else '''' end +
						case when isnull(isFulfillment, 0) = 1 then ''Fulfillment, '' else '''' end +
						case when isnull(isMonitorMessage, 0) = 1 then ''Monitoring, '' else '''' end as sourceType
--					+ case when isnull(allMessages, 0) = 1 then ''All Messages, '' else '''' end

				from messageRules a
				left outer join dm_serverGroups b on a.ukey_group = b.ukey
				where userName = @cUserName
			) a
		order by sourceType, ruleDescription
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_dashboard_availabilitySummary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_dashboard_availabilitySummary]
as
begin

	select a.*,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		identity(int) as ukey
		into #results
		from (
			select
				a.serverName,
				min(a.ymd) as earliestData,
				max(a.ymd) as latestData,
				min(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as earliestDrop,
				max(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as latestDrop,
				max(case when a.isServerPingable = 1 and a.isRouterPingable = 1 then a.ymd else null end) as latestSuccess,
				count(distinct case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ukey else null end) as droppedPings,
				count(*) as totalPings
				from pingLog a (nolock)
				where a.ymd >= dateAdd(hour, -2, getDate())
				group by a.serverName
--				having count(*) > 5
			) a

	select
		c.groupName,
		isnull(b.friendlyName, b.serverName) as friendlyName,
		isnull(right(convert(varchar(16), latestDrop, 120), 11), ''NONE'') as latestDrop,
		isnull(right(convert(varchar(16), latestSuccess, 120), 11), ''NONE'') as latestSuccess,
		isnull(right(convert(varchar(16), latestData, 120), 11), ''NONE'') as latestData,
		droppedPings, totalPings, failureRate, availability,
		convert(varchar(10), dateDiff(hour, isnull(latestDrop, earliestData), latestData)) + ''hrs'' as uptime,
		case
				when abs(dateDiff(minute, latestData, getDate())) > 60 then ''N/M''
				when latestDrop > isnull(latestSuccess, ''1980-01-01'')
					then ''DOWN''
				when latestDrop > isnull(latestSuccess, ''1980-01-01'')
					and failureRate > 5 then ''ALERT''
				when latestDrop > dateAdd(hour, -3, isnull(latestSuccess, ''1980-01-01''))
					and failureRate > 25 then ''WARNING''
				when latestDrop > isnull(latestSuccess, ''1980-01-01'')
					and failureRate > 10 then ''FAILING''
				else ''Online''
			end as status
		from #results a
		join dm_servers b on a.serverName = b.serverName
		join dm_serverGroups c on b.ukey_group = c.ukey
		order by groupName, friendlyName

	drop table #results

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_weeklyTailReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'create procedure [pr_rpt_weeklyTailReport]
as
begin
	-- First, detail on the time and duration of outages in the last week
	declare @dStartDate dateTime
	declare @nThisUkey int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @dLatestViewData dateTime

	set @dStartDate = dateAdd(week, -1, convert(varchar(10), getDate(), 120))

	create table #tailDetail (ukey int identity, serverName varchar(200),
		eventDetail varchar(1000), startDate dateTime, endDate dateTime)

	--*********************************************************************************************
	-- Servers unpingable
	--*********************************************************************************************
	create table #outages (serverName varchar(100), startDate dateTime, endDate dateTime)

	select distinct serverName
		into #activeServers
		from pingLog (nolock)
		where isServerPingable = 1

	set @dLatestViewData = (select max(ymd) from v_pingLog_all)

	insert into #outages (serverName, startDate, endDate)
	select a.serverName, ymd as outageStart, null as endDate
		from v_pingLog_all a (nolock)
		join #activeServers b on a.serverName = b.serverName
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

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select a.serverName,
		''Server unpingable at '' +
			convert(varchar(20), min(startDate), 120) +
			case when endDate is null
				then '', and is still OFFLINE''
				else '' for '' + convert(varchar(20), convert(decimal(10,2), convert(decimal(10,2), dateDiff(minute, min(startDate), endDate))/60.00)) + '' hours(s)''
				end as eventDetail,
		min(a.startDate) as startDate,
		endDate as endDate
		from #outages a
		group by serverName, endDate

	--*********************************************************************************************
	-- Website outages
	--*********************************************************************************************
	select ukey_url, ymd as outageStart
		into #websiteOutages
		from websiteMonitor..monitoredURLs_history a
		where a.ymd >= @dStartDate
			and isAvailable = 0

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select c.friendlyName,
		''Website unavailable at '' + convert(varchar(20), min(a.outageStart), 120) +
			case when b.outageStop is null then '', and is still offline''
				else '' for '' + convert(varchar(20), dateDiff(minute, min(a.outageStart), b.outageStop)) + '' minutes.''
				end as eventDetail,
		min(a.outageStart) as startDate, b.outageStop as endDate
		from #websiteOutages a
		left outer join (
			select a.ukey_url, a.outageStart, min(b.ymd) as outageStop
				from #websiteOutages a
				join websiteMonitor..monitoredURLs_history b on a.ukey_url = b.ukey_url
					and b.isAvailable = 1
					and b.ymd > a.outageStart
					and b.ymd >= @dStartDate
				group by a.ukey_url, a.outageStart
			) b on a.ukey_url = b.ukey_url
				and a.outageStart = b.outageStart
		join websiteMonitor..monitoredURLs c on a.ukey_url = c.ukey

		group by c.friendlyName, b.outageStop
		order by c.friendlyName, min(a.outageStart)

	--*********************************************************************************************
	-- Breaks in communication
	--*********************************************************************************************
	set @dLatestViewData = (select max(ymd) from v_pingLog_all)

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select
		left(substring(subject, charindex(''with '', subject) + 5, 99), charindex('' '', substring(subject, charindex(''with '', subject) + 5, 99)) - 1) as serverName,
		''Communication momentarily interrupted at '' + convert(varchar(20), a.ymd, 120) + ''.'',
		ymd as startDate,
		ymd as endDate
		from v_notificationLog_all a (nolock)
		where
			serverName = @@serverName
			and subject like ''%lost communication%''
			and message not like ''%transaction log%''
			and message not like ''%disk space%''
			and ymd >= @dStartDate
		order by ymd

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select
		left(substring(subject, charindex(''with '', subject) + 5, 99), charindex('' '', substring(subject, charindex(''with '', subject) + 5, 99)) - 1) as serverName,
		''Communication momentarily interrupted at '' + convert(varchar(20), a.ymd, 120) + ''.'',
		ymd as startDate,
		ymd as endDate
		from notificationLog a (nolock)
		where
			serverName = @@serverName
			and subject like ''%lost communication%''
			and message not like ''%transaction log%''
			and message not like ''%disk space%''
			and ymd >= @dStartDate
			and ymd > @dLatestViewData
		order by ymd

	--*********************************************************************************************
	-- Other big issues
	--*********************************************************************************************

	create table #otherErrors (serverName varchar(100), subject varchar(500), ymd dateTime)

	insert into #otherErrors (serverName, subject, ymd)
	select serverName, left(subject, 500), ymd
		from v_notificationLog_all
		where
			(
				severity = 1
				or message like ''%Event log service was started%''
				or subject like ''%temperature%''
				or subject like ''%array controller%''
				or subject like ''%degraded%''
				or subject like ''%drive%is down to''
				or subject like ''%CPU load has triggered an alert%''
				)
			and isConnectivity = 0
			and serverName <> @@serverName
			and serverName <> ''2K3DEVSEED3''
			and ymd >= @dStartDate

	insert into #otherErrors (serverName, subject, ymd)
	select serverName, left(subject, 500), ymd
		from notificationLog
		where
			(
				severity = 1
				or message like ''%Event log service was started%''
				or subject like ''%temperature%''
				or subject like ''%array controller%''
				or subject like ''%degraded%''
				or subject like ''%drive%is down to''
				or subject like ''%CPU load has triggered an alert%''
				)
			and isConnectivity = 0
			and serverName <> @@serverName
			and serverName <> ''2K3DEVSEED3''
			and ymd >= @dStartDate
			and ymd > @dLatestViewData

	insert into #tailDetail (serverName, eventDetail, startDate, endDate)
	select serverName,
		case
			when subject like ''%temperature%'' then ''Server temperature exceeded thresholds''
			when subject like ''%array controller%'' or subject like ''%degraded%'' then ''Disk subsystem failure''
			when subject like ''%drive%is down to'' then ''Disk space below threshold''
			when subject like ''%CPU load has triggered an alert%'' then ''CPU utilization above threshold''
			else subject
			end + '' ('' + max(subject)  + '')''  --substring(max(subject), charindex('':'', max(subject)) + 1, 200)
			as eventDetail,
		min(ymd) as startDate,
		max(ymd) as endDate
		from #otherErrors
		group by serverName, case
			when subject like ''%temperature%'' then ''Server temperature exceeded thresholds''
			when subject like ''%array controller%'' or subject like ''%degraded%'' then ''Disk subsystem failure''
			when subject like ''%drive%is down to'' then ''Disk space below threshold''
			when subject like ''%CPU load has triggered an alert%'' then ''CPU utilization above threshold''
			else subject
			end

	--***********************************************************************************************************
	-- Results
	--***********************************************************************************************************

	select distinct isnull(isnull(b.friendlyName, b.serverName), a.serverName ) as serverName, eventDetail, startDate, endDate
		from #tailDetail a
		left outer join dm_servers b on a.serverName = b.serverName
		left outer join dm_serverGroups c on b.ukey_group = c.ukey
		where c.isProduction = 1
			or c.ukey is null
		order by startDate, isnull(isnull(b.friendlyName, b.serverName), a.serverName )

	drop table #websiteOutages
	drop table #outages
	drop table #activeServers
	drop table #tailDetail
	drop table #otherErrors

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
