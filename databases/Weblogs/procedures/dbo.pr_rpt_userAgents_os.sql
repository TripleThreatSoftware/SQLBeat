/****** Object:  StoredProcedure [dbo].[pr_rpt_userAgents_os]    Script Date: 12/04/2009 18:52:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_userAgents_os 'osaweb'

CREATE procedure [dbo].[pr_rpt_userAgents_os] (@cSiteName varchar(100))
as
begin

	select
		c.osName,
		sum(uniques) as uniques,
		sum(requests) as requests,
		sum(pageviews) as pageviews,
		sum(pageRequests) as pageRequests,
		sum(pageNotFoundErrors) as pageNotFoundErrors,

		sum(case when c.isHuman = 1 then uniques else 0 end) as uniques_human,
		sum(case when c.isHuman = 1 then requests else 0 end) as requests_human,
		sum(case when c.isHuman = 1 then pageviews else 0 end) as pageviews_human,
		sum(case when c.isHuman = 1 then pageRequests else 0 end) as pageRequests_human

		from mart_userAgent_byday a
		join dm_userAgent c (nolock) on a.ukey_userAgent = c.ukey
		join dm_sites f (nolock) on a.ukey_site = f.ukey
			and f.friendlyName = @cSiteName

		where a.ymd >= dateAdd(week, -1, getDate())

		group by c.osName
		having sum(requests) > 50
		order by requests desc

end
GO
