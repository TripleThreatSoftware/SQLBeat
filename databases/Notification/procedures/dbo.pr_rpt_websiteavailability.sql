SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---- exec pr_rpt_websiteavailability null, null
ALTER procedure [dbo].[pr_rpt_websiteavailability] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
	--declare @dStartDate dateTime, @dEndDate dateTime

	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(month, -1, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	declare @websiteOutages table (ukey_url int, outageStart dateTime)
	declare @outageSummary table (ukey_url int, minutesOffline bigint)

	insert into @websiteOutages
	select ukey_url, ymd as outageStart
		from websiteMonitor.dbo.monitoredURLs_history a (nolock)
		join websiteMonitor.dbo.monitoredURLs b (nolock) on a.ukey_url = b.ukey
--			and a.ymd >= b.firstGoodData
		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)
			and isAvailable = 0

	insert into @outageSummary
	select ukey_url, sum(minutesOffline) as minutesOffline
		from (
			select a.ukey_url, b.outageStop,
				convert(bigint, ceiling((convert(decimal(20,2), dateDiff(millisecond, min(a.outageStart), b.outageStop))/1000.00)/60.00)) as  minutesOffline
				from @websiteOutages a
				left outer join (
					select a.ukey_url, a.outageStart, min(b.ymd) as outageStop
						from @websiteOutages a
						join websiteMonitor.dbo.monitoredURLs_history b (nolock) on a.ukey_url = b.ukey_url
							and b.ymd > a.outageStart
							and b.isAvailable = 1
							and b.ymd >= @dStartDate
							and b.ymd < dateAdd(day, 1, @dEndDate)
						group by a.ukey_url, a.outageStart
					) b on a.ukey_url = b.ukey_url
						and a.outageStart = b.outageStart
				group by a.ukey_url, b.outageStop
			) a
		group by ukey_url

	select c.friendlyName,
		totalPings as connectionAttempts,
		droppedPings as connectionFailures,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
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
				join websiteMonitor.dbo.monitoredURLs b (nolock) on a.ukey_url = b.ukey
					and b.isEnabled = 1
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
		order by friendlyName
end
