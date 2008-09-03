	declare @dStartDate dateTime
	declare @dEndDate dateTime

	set @dEndDate = dateAdd(hour, -12, convert(varchar(10), '2008-08-27 11:00:00.000', 120))
	set @dStartDate = dateAdd(day, -7, @dEndDate)

--	set @dEndDate = dateAdd(hour, -12, convert(varchar(10), getDate(), 120))
--	set @dStartDate = dateAdd(day, -7, @dEndDate)

	select ukey_site, ukey_uriStem, requestStatus,
		count(*) as numRequests,
		min(ymd) as firstSeen,
		max(ymd) as lastSeen
		into #allRequests
		from v_fact_weblogs_all a
		where ymd >= @dStartDate
			and ymd < dateAdd(day, 1, @dEndDate)
		group by ukey_site, ukey_uriStem, requestStatus

	select
		b.friendlyName,
		mart.dbo.fn_classifySubsite(b.friendlyName, c.uriStem) as subsite,
		sum(numRequests) as numRequests
		into #overallTraffic
		from #allRequests a
		join dm_sites b on a.ukey_site = b.ukey
		join dm_uriStem c on a.ukey_uriStem = c.ukey
		where requestStatus <> '404'
		group by b.friendlyName, mart.dbo.fn_classifySubsite(b.friendlyName, c.uriStem)

	select ukey_site, ukey_uriStem,
		sum(numRequests) as numSeen,
		min(firstSeen) as firstSeen,
		max(lastSeen) as lastSeen
		into #errorsSeen
		from #allRequests
		where requestStatus = '404'
		group by ukey_site, ukey_uriStem

	select
		a.friendlyName as siteName,
		mart.dbo.fn_classifySubsite(a.friendlyName, d.uriStem) as subsite,
		d.uriStem,

		a.numRequests as numErrors,
		dateDiff(hour, a.firstSeen, a.lastSeen) as hours,
		convert(decimal(20,6), convert(decimal(20,6), a.numRequests) / convert(decimal(20,6), dateDiff(hour, @dStartDate, @dEndDate))) as errorsPerHour

		from (
			select
				c.friendlyName,
				ukey_uriStem,
				sum(numSeen) as numRequests,
				convert(varchar(10), min(firstSeen), 120) as firstSeen,
				convert(varchar(10), max(lastSeen), 120) as lastSeen
				from #errorsSeen a
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and c.friendlyName like 'PRO%'
				group by c.friendlyName, ukey_uriStem
			) a

		join dm_uriStem d (nolock) on a.ukey_uriStem = d.ukey

		where dateDiff(hour, a.firstSeen, a.lastSeen) > 0

	select a.*
		, convert(decimal(20,6), a.numErrors) / convert(decimal(20,6), e.numRequests) as errorsPerRequest

		from (
			select
				a.friendlyName as siteName,
				mart.dbo.fn_classifySubsite(a.friendlyName, d.uriStem) as subsite,
				sum(a.numRequests) as numErrors,
				convert(decimal(20,6), convert(decimal(20,6), sum(a.numRequests)) / convert(decimal(20,6), dateDiff(hour, @dStartDate, @dEndDate))) as errorsPerHour
				from (
					select
						c.friendlyName,
						ukey_uriStem,
						sum(numSeen) as numRequests,
						convert(varchar(10), min(firstSeen), 120) as firstSeen,
						convert(varchar(10), max(lastSeen), 120) as lastSeen
						from #errorsSeen a
						join dm_sites c (nolock) on a.ukey_site = c.ukey
							and c.friendlyName like 'PRO%'
						group by c.friendlyName, ukey_uriStem
					) a

				join dm_uriStem d (nolock) on a.ukey_uriStem = d.ukey

				where dateDiff(hour, a.firstSeen, a.lastSeen) > 0
				group by a.friendlyName, mart.dbo.fn_classifySubsite(a.friendlyName, d.uriStem)
			) a
		join #overallTraffic e on a.sitename = e.friendlyName
			and a.subsite = e.subsite
		order by a.siteName, a.subsite


--drop table #errorsSeen
--drop table #overallTraffic
--drop table #allRequests
--end
