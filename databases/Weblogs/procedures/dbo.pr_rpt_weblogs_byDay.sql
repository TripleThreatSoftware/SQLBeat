/****** Object:  StoredProcedure [dbo].[pr_rpt_weblogs_byDay]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_weblogs_byDay 'PRO - OSAWeb', null, null
CREATE procedure [dbo].[pr_rpt_weblogs_byDay] (@cSiteName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin
	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(year, -2, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	declare @dailyData table (ymd dateTime, uniques int, pageviews int, requests int, pageRequests int, errorPageviews int, pageNotFoundErrors int)

	insert into @dailyData
	select ymd,
		sum(uniques) as uniques,
		sum(pageviews) as pageviews,
		sum(requests) as requests,
		sum(pageRequests) as pageRequests,
		sum(errorPageviews) as errorPageviews,
		sum(pageNotFoundErrors) as pageNotFoundErrors
		from mart_site_byday a
		join dm_sites b on a.ukey_site = b.ukey
			and b.friendlyName = @cSiteName
		group by ymd

	declare @summary table (ymd dateTime, uniques int, pageviews int, requests int, pageRequests int, errorPageviews int, pageNotFoundErrors int)
	insert into @summary
	select a.ymd,
		avg(b.uniques), avg(b.pageviews), avg(b.requests), avg(b.pageRequests), avg(b.errorPageviews), avg(b.pageNotFoundErrors)
		from @dailyData a
		join @dailyData b on datePart(weekDay, a.ymd) = datePart(weekday, b.ymd)
			and b.ymd >= dateAdd(week, -4, a.ymd)
		group by a.ymd

	select
		convert(varchar(10), a.ymd, 120) as ymd,
		a.serverHours,
		a.uniques,
			c.uniques as uniques_avg,
			case when c.uniques <> 0 then convert(decimal(10,2), 100 * (convert(decimal(10,2), a.uniques) / convert(decimal(10,2), c.uniques))) else 0 end as uniques_relative,
		a.pageviews,
			c.pageviews as pageviews_avg,
			case when c.pageviews <> 0 then convert(decimal(10,2), 100 * (convert(decimal(10,2), a.pageviews) / convert(decimal(10,2), c.pageviews))) else 0 end as pageviews_relative,
		a.requests,
			c.requests as requests_avg,
		a.pageRequests,
			c.pageRequests as pageRequests_avg,
		a.pageNotFoundErrors,
			c.pageNotFoundErrors as pageNotFoundErrors_avg,

		case when a.pageRequests <> 0 then convert(decimal(10,4), (convert(decimal(10,2), a.pageNotFoundErrors) / convert(decimal(10,2), a.pageRequests))) else 0 end as errorsPerPageRequest,
		case when a.pageviews <> 0 then convert(decimal(10,4), (convert(decimal(10,2), a.pageNotFoundErrors) / convert(decimal(10,2), a.pageviews))) else 0 end as errorsPerPageview

		from (
			select ymd,
				sum(serverHours) as serverHours,
				sum(uniques) as uniques,
				sum(pageviews) as pageviews,
				sum(requests) as requests,
				sum(pageRequests) as pageRequests,
--				sum(errorPageviews) as errorPageviews,
				sum(pageNotFoundErrors) as pageNotFoundErrors
				from mart_site_byday a
				join dm_sites b on a.ukey_site = b.ukey
					and b.friendlyName = @cSiteName
				where a.ymd >= @dStartDate
					and a.ymd < dateAdd(day, 1, @dEndDate)
				group by a.ymd
			) a
		join @summary c on a.ymd = c.ymd
		order by a.ymd desc
end
GO
