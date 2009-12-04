/****** Object:  StoredProcedure [dbo].[pr_rpt_weblogs_byHour]    Script Date: 12/04/2009 18:52:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_weblogs_byHour 'osaweb'

CREATE procedure [dbo].[pr_rpt_weblogs_byHour] (@cSiteName varchar(100))
as
begin

	select
		convert(varchar(10), ymd, 120) as ymd,
		datePart(hour, ymd) as ymd_hour,
		count(distinct ukey_sourceFile) as numFiles,
		count(distinct
			case when isnull(appSessionID, '') <> '' then appSessionID
				when isnull(sessionID, '') <> '' then sessionID
				else convert(varchar(20), ukey_clientIP)
				end + convert(varchar(20), ukey_userAgent)) as uniques,
		count(a.ukey) as requests,
		sum(case when e.isPage = 1 and a.requestStatus <> '404' then 0 else 0 end) as pageviews,
		sum(case when e.isPage = 1 then 1 else 0 end) as pageRequests,
		sum(case when a.requestStatus = '404' then 1 else 0 end) as pageNotFoundErrors,

		count(distinct case when c.isHuman = 1 then convert(varchar(20), ukey_clientIP) + convert(varchar(20), ukey_userAgent) else null end) as uniques_human,
		sum(case when c.isHuman = 1 then 1 else 0 end) as requests_human,
		sum(case when c.isHuman = 1 and e.isPage = 1 and a.requestStatus <> '404' then 1 else 0 end) as pageviews_human,
		sum(case when c.isHuman = 1 and e.isPage = 1 then 1 else 0 end) as pageRequests_human

		from v_fact_weblogs_all a
		join dm_userAgent c (nolock) on a.ukey_userAgent = c.ukey
		join dm_uriStem e (nolock) on a.ukey_uriStem = e.ukey
		join dm_sites f (nolock) on a.ukey_site = f.ukey
			and f.friendlyName = @cSiteName

		where a.ymd >= dateAdd(hour, -48, getDate())

		group by convert(varchar(10), ymd, 120), datePart(hour, ymd)
		order by convert(varchar(10), ymd, 120), datePart(hour, ymd)

end
GO
