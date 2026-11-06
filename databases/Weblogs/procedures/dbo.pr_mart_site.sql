/****** Object:  StoredProcedure [dbo].[pr_mart_site]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_mart_site '2025-07-01', '2025-09-20'
CREATE procedure [dbo].[pr_mart_site] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
	set @dStartDate = convert(varchar(10), @dStartDate, 120)
	set @dEndDate = convert(varchar(10), @dEndDate, 120)

	delete from mart_site_byday where ymd >= @dStartDate and ymd <= @dEndDate

	insert into mart_site_byday (ukey_site, ymd, serverHours, logFiles, requests, pageNotFoundErrors, allErrors)
	select
		a.ukey_site,
		convert(varchar(10), ymd, 120) as ymd,
		count(distinct convert(varchar(2), datePart(hour, ymd))) as serverHours,
		count(distinct a.ukey_sourceFile) as logFiles,

		count(a.ukey) as requests,
		sum(case when a.requestStatus = '404' then 1 else 0 end) as pageNotFoundErrors,
		sum(case when a.requestStatus like '4%' or a.requestStatus like '5%' then 1 else 0 end) as allErrors

		from v_fact_weblogs_all a (nolock)

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by ukey_site, convert(varchar(10), ymd, 120)



	update mart_site_byday
		set uniques = b.uniques,
			uniques_human = b.uniques_human,
			requests_human = b.requests_human,
			uniques_nonhuman = b.uniques_nonhuman,
			requests_nonhuman = b.requests_nonhuman
		from mart_site_byday a
		join (
			select
				ukey_site,
				convert(varchar(10), a.ymd, 120) as ymd,

				count(distinct case
					when isnull(a.appSessionID, '') <> '' then appSessionID
					when isnull(a.sessionID, '') <> '' then sessionID
					else convert(varchar(20), a.ukey_clientIP)
					end +
					convert(varchar(20), a.ukey_userAgent)
					) as uniques,
				count(distinct case
					when b.isHuman = 0 or c.isBlocked = 1 then null
					when isnull(a.appSessionID, '') <> '' then appSessionID
					when isnull(a.sessionID, '') <> '' then sessionID
					else convert(varchar(20), a.ukey_clientIP)
					end +
					convert(varchar(20), a.ukey_userAgent)
					) as uniques_human,
				sum(case
					when b.isHuman = 0 or c.isBlocked = 1 then 0
					else 1
					end) as requests_human,

				count(distinct case
					when b.isHuman = 1 and c.isBlocked = 0 then null
					when isnull(a.appSessionID, '') <> '' then appSessionID
					when isnull(a.sessionID, '') <> '' then sessionID
					else convert(varchar(20), a.ukey_clientIP)
					end +
					convert(varchar(20), a.ukey_userAgent)
					) as uniques_nonhuman,
				sum(case
					when b.isHuman = 0 or c.isBlocked = 1 then 1
					else 0
					end) as requests_nonhuman

				--sum(convert(bigint, uniques)) as uniques,
				--sum(convert(bigint, case when b.isHuman = 1 then uniques else 0 end)) as uniques_human,
				--sum(convert(bigint, case when b.isHuman = 1 then requests else 0 end)) as requests_human,
				--sum(convert(bigint, case when b.isHuman = 0 then uniques else 0 end)) as uniques_nonhuman,
				--sum(convert(bigint, case when b.isHuman = 0 then requests else 0 end)) as requests_nonhuman
				from v_fact_weblogs_all a (nolock)
				join dm_userAgent b (nolock) on a.ukey_userAgent = b.ukey
				join dm_clientIP c (nolock) on a.ukey_clientIP = c.ukey
				where a.ymd >= @dStartDate
					and a.ymd < dateAdd(day, 1, @dEndDate)
				group by a.ukey_site, convert(varchar(10), a.ymd, 120)
			) b on a.ukey_site = b.ukey_site
			and a.ymd = b.ymd


	select
		a.ukey_site,
		a.ukey_uristem,
		a.ukey_userAgent,
		a.ukey_clientIP,
		a.requestStatus,
		convert(varchar(10), ymd, 120) as ymd,
		count(*) as numRequests,

		count(distinct
			case
				when isnull(appSessionID, '') <> '' then appSessionID
				when isnull(sessionID, '') <> '' then sessionID
				else convert(varchar(20), ukey_clientIP)
				end +
				convert(varchar(20), ukey_userAgent)
			) as uniques,

		avg(timeTaken) as pageLoadTime

		into #results

		from v_fact_weblogs_all a

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by convert(varchar(10), ymd, 120), datePart(hour, ymd),
			a.ukey_site,
			a.ukey_clientIP,
			a.ukey_uristem,
			a.ukey_userAgent,
			a.requestStatus

	-- grab these details from the other mart tables
	update mart_site_byday
		set pageviews = b.pageviews,
			pageRequests = b.pageRequests,
			pageviews_human = b.pageviews_human,
			pageRequests_human = b.pageRequests_human,
			pageviews_nonhuman = b.pageviews_nonhuman,
			pageRequests_nonhuman = b.pageRequests_nonhuman,
			pageLoadTime = b.pageLoadTime
		from mart_site_byday a
		join (
			select
				ukey_site,
				ymd,
				sum(convert(bigint, case when requestStatus <> '404' then numRequests else 0 end)) as pageviews,
				sum(convert(bigint, numRequests)) as pageRequests,
				sum(convert(bigint, case when requestStatus <> '404' then numRequests_human else 0 end)) as pageviews_human,
				sum(convert(bigint, numRequests_human)) as pageRequests_human,
				sum(convert(bigint, case when requestStatus <> '404' then numRequests - numRequests_human else 0 end)) as pageviews_nonhuman,
				sum(convert(bigint, numRequests - numRequests_human)) as pageRequests_nonhuman,
				avg(convert(bigint, pageLoadTime)) as pageLoadTime
				from (
					select
						a.ukey_site,
						a.requestStatus,
						a.ymd,
						sum(numRequests) as numRequests,
						sum(case when c.isHuman = 1 and d.isBlocked = 0 then numRequests else 0 end) as numRequests_human,
						sum(uniques) as uniques,
						sum(case when c.isHuman = 1 and d.isBlocked = 0 then uniques else 0 end) as uniques_human,
						sum(pageLoadTime * numRequests) / sum(numRequests) as pageLoadTime

						from #results a
						join dm_uriStem b on a.ukey_uriStem = b.ukey
							and b.isPage = 1
						join dm_userAgent c on a.ukey_userAgent = c.ukey
						join dm_clientIP d on a.ukey_clientIP = d.ukey

						group by a.ymd, a.ukey_site, a.requestStatus
					) a
				group by ukey_site, ymd
			) b on a.ukey_site = b.ukey_site
			and a.ymd = b.ymd
		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

end
GO
