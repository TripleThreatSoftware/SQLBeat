/****** Object:  StoredProcedure [dbo].[pr_rpt_weblogs_byWeek]    Script Date: 12/04/2009 18:52:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_weblogs_byWeek null, null
CREATE procedure [dbo].[pr_rpt_weblogs_byWeek] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
--	declare @dStartDate dateTime
--	declare @dEndDate dateTime

	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(month, -6, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	declare @summary table (friendlyName varchar(100), webServer varchar(100),
		uniques int, pageviews int, requests int, pageRequests int, errorPageviews int, pageNotFoundErrors int)
	insert into @summary
	select friendlyName, webServer, avg(uniques), avg(pageviews), avg(requests), avg(pageRequests), avg(errorPageviews), avg(pageNotFoundErrors)
		from (
			select isnull(b.friendlyName, 'N/A') as friendlyName, b.webServer,
				sum(uniques) as uniques,
				sum(pageviews) as pageviews,
				sum(requests) as requests,
				sum(pageRequests) as pageRequests,
				sum(errorPageviews) as errorPageviews,
				sum(pageNotFoundErrors) as pageNotFoundErrors
				from mart_site_byday a
				join dm_sites b on a.ukey_site = b.ukey
				group by isnull(b.friendlyName, 'N/A'), b.webServer, datePart(week, ymd)
			) a
		group by friendlyName, webServer

	select
		a.friendlyName,
		a.webServer,
		dateAdd(day, ((a.[week] - 1) * 7) - datePart(weekday, a.ymd), convert(varchar(4), datePart(year, a.ymd)) + '-01-01') as ymd,
		a.uniques,
			c.uniques as uniques_avg,
			case when c.uniques <> 0 then convert(decimal(10,2), 100 * (convert(decimal(10,2), a.uniques) / convert(decimal(10,2), c.uniques))) else 0 end as uniques_relative,
			a.uniques_human, a.uniques_nonHuman,
		a.pageviews,
			c.pageviews as pageviews_avg,
			case when c.pageviews <> 0 then convert(decimal(10,2), 100 * (convert(decimal(10,2), a.pageviews) / convert(decimal(10,2), c.pageviews))) else 0 end as pageviews_relative,
			a.pageviews_human, a.pageviews_nonHuman,
		a.requests, c.requests as requests_avg, a.requests_human, a.requests_nonHuman,
		a.pageRequests, c.pageRequests as pageRequests_avg, a.pageRequests_human, a.pageRequests_nonHuman,
		a.errorPageviews, c.errorPageviews as errorPageviews_avg, a.errorPageviews_human, a.errorPageviews_nonHuman,
		a.loggedErrors,
		a.pageNotFoundErrors, c.pageNotFoundErrors as pageNotFoundErrors_avg
		from (
			select isnull(b.friendlyName, 'N/A') as friendlyName,
				b.webServer,
				min(ymd) as ymd,
				datePart(week, ymd) as week,
				sum(uniques) as uniques,
				sum(uniques_human) as uniques_human,
				sum(uniques_nonHuman) as uniques_nonHuman,
				sum(pageviews) as pageviews,
				sum(pageviews_human) as pageviews_human,
				sum(pageviews_nonHuman) as pageviews_nonHuman,
				sum(requests) as requests,
				sum(requests_human) as requests_human,
				sum(requests_nonHuman) as requests_nonHuman,
				sum(pageRequests) as pageRequests,
				sum(pageRequests_human) as pageRequests_human,
				sum(pageRequests_nonHuman) as pageRequests_nonHuman,
				sum(errorPageviews) as errorPageviews,
				sum(errorPageviews_human) as errorPageviews_human,
				sum(errorPageviews_nonHuman) as errorPageviews_nonHuman,
				sum(loggedErrors) as loggedErrors,
				sum(pageNotFoundErrors) as pageNotFoundErrors
				from mart_site_byday a
				join dm_sites b on a.ukey_site = b.ukey
				where a.ymd >= @dStartDate
					and a.ymd <= @dEndDate
				group by isnull(b.friendlyName, 'N/A'), b.webServer, datePart(week, ymd)
			) a
		join @summary c on a.friendlyName = c.friendlyName
			and a.webServer = c.webServer
		order by a.friendlyName, a.webServer, a.ymd
end
GO
