SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_siteSummary 'AppDb', null, null
ALTER procedure [dbo].[pr_rpt_siteSummary] (@cSiteName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin
	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(month, -3, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	select ymd,
		sum(uniques) as uniques,
--		sum(uniques_human) as uniques_human,
--		sum(uniques_nonHuman) as uniques_nonHuman,
		sum(pageviews) as pageviews,
--		sum(pageviews_human) as pageviews_human,
--		sum(pageviews_nonHuman) as pageviews_nonHuman,
		sum(requests) as requests,
--		sum(requests_human) as requests_human,
--		sum(requests_nonHuman) as requests_nonHuman,
		sum(pageRequests) as pageRequests,
--		sum(pageRequests_human) as pageRequests_human,
--		sum(pageRequests_nonHuman) as pageRequests_nonHuman,
		sum(errorPageviews) as errorPageviews,
--		sum(errorPageviews_human) as errorPageviews_human,
--		sum(errorPageviews_nonHuman) as errorPageviews_nonHuman,
		sum(pageNotFoundErrors) as pageNotFoundErrors
		from mart_site_byday a (nolock)
		join dm_sites b on a.ukey_site = b.ukey
			and b.friendlyName = @cSiteName
		where a.ymd >= @dStartDate
			and a.ymd <= @dEndDate
		group by a.ymd
		order by a.ymd

end
