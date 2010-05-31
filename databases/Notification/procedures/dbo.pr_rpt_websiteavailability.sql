SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---- exec pr_rpt_websiteavailability null, null
ALTER procedure [dbo].[pr_rpt_websiteavailability] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
--	declare @dStartDate dateTime, @dEndDate dateTime

	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(month, -1, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	declare @websiteOutages table (ukey_url int, outageStart dateTime)
	declare @outageSummary table (ukey_url int, minutesOffline bigint)

	select c.ukey as ukey_url, a.ymd, a.currentState, b.keyName as friendlyName, a.ukey
		into #stateChanges
		from notification.dbo.stateLog a (nolock)
		join notification.dbo.dm_stateKeys b (nolock) on a.ukey_stateKey = b.ukey
			and b.category = 'WebsiteMonitor'
		join monitoredURLs c (nolock) on b.keyName = c.friendlyName
		where a.ymd >= @dStartDate
			and a.ymd <= @dEndDate
			and a.currentState = 'Down'

	insert into @websiteOutages
	select ukey_url, ymd
		from #stateChanges
		where currentState = 'Down'

	insert into @outageSummary
	select ukey_url, sum(isnull(minutesOffline, 0)) as minutesOffline
		from (
			select a.ukey_url, b.outageStop,
				dateDiff(minute, min(a.outageStart), isnull(b.outageStop, getDate()))  minutesOffline
				from @websiteOutages a
				left outer join (
					select a.ukey_url, a.outageStart, min(b.ymd) as outageStop
						from @websiteOutages a
						join #stateChanges b (nolock) on a.ukey_url = b.ukey_url
							and b.ymd > a.outageStart
							and b.currentState = 'Up'
						group by a.ukey_url, a.outageStart
					) b on a.ukey_url = b.ukey_url
						and a.outageStart = b.outageStart
				group by a.ukey_url, b.outageStop
			) a
		group by ukey_url


	select c.friendlyName,
		totalPings as connectionAttempts,
		droppedPings as connectionFailures,
		convert(decimal(20,2), convert(decimal(30,6), droppedPings)/convert(decimal(30,6), totalPings) * 100) as failureRate,
		convert(decimal(20,2), convert(decimal(30,6), (totalPings - droppedPings))/convert(decimal(30,6), totalPings) * 100) as availability,
		b.minutesOffline,
		latestDrop, earliestData, latestData

		from (
			select
				a.ukey_url,
				min(a.ymd) as earliestData,
				max(a.ymd) as latestData,
				min(case when a.isAvailable = 0 then a.ymd else null end) as earliestDrop,
				max(case when a.isAvailable = 0 then a.ymd else null end) as latestDrop,
				max(case when a.isAvailable = 1 then a.ymd else null end) as latestSuccess,
				count(distinct case when a.isAvailable = 0 then a.ukey else null end) as droppedPings,
				count(*) as totalPings
				from websiteMonitor.dbo.monitoredURLs_history a (nolock)
--					and a.ymd >= b.firstGoodData
				where a.message not like '%access is denied%'
					and a.message not like '%bad request%'
	--				and a.message not like '%download of the specified resource has failed%'
	--				and a.message not like '%cannot locate the resource specified%'
					and a.ymd >= @dStartDate
					and a.ymd < dateAdd(day, 1, @dEndDate)
				group by a.ukey_url
			) a
		left outer join @outageSummary b on a.ukey_url = b.ukey_url
		join websiteMonitor.dbo.monitoredURLs c (nolock) on a.ukey_url = c.ukey
			and c.isEnabled = 1
		order by friendlyName

	drop table #stateChanges
end
