SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_rpt_userAgents_browsers 'AppDb'
-- exec weblogs..pr_rpt_userAgents_browsers 'AppDb'
-- select * from dm_sites

ALTER procedure [dbo].[pr_rpt_userAgents_browsers] (@cSiteName varchar(100))
as
begin

	select
		case
			when c.browserName like '%msie 7%' then 'MSIE 7.x'
			when c.browserName like '%msie 6%' then 'MSIE 6.x'
			when c.browserName like '%msie 5%' then 'MSIE 5.x'
			when c.browserName like '%blackberry%' then 'Blackberry'
			when c.browserName like '%iphone%' then 'IPhone'
			when c.browserName like '%ipad%' then 'IPad'
			when c.browserName like '%firefox%' then 'FireFox'
			when c.browserName like '%safari%' then 'Safari'
			when c.browserName like '%netscape%' then 'Netscape'
			when c.browserName like '%mozilla%' then 'Mozilla'
			when c.browserName like '%Opera%' then 'Opera'
			when c.browserName like '%crawler%' or c.browserName like '%bot%' or c.browserName like '%baidu%' or c.browserName like '%spider%' then 'Bot'
			when charindex('/', c.browserName) > 0 then left(c.browserName, charindex('/', c.browserName) - 1)
			else c.browserName end
			as browserName,
		sum(uniques) as uniques,
		sum(requests) as requests,
		sum(pageviews) as pageviews,
		sum(pageRequests) as pageRequests,
		sum(pageNotFoundErrors) as pageNotFoundErrors,

		sum(case when c.isHuman = 1 then uniques else 0 end) as uniques_human,
		sum(case when c.isHuman = 1 then requests else 0 end) as requests_human,
		sum(case when c.isHuman = 1 then pageviews else 0 end) as pageviews_human,
		sum(case when c.isHuman = 1 then pageRequests else 0 end) as pageRequests_human

		from mart_userAgent_byday a (nolock)
		join dm_userAgent c (nolock) on a.ukey_userAgent = c.ukey
		join dm_sites f (nolock) on a.ukey_site = f.ukey
			and f.friendlyName = @cSiteName

		where a.ymd >= dateAdd(week, -2, getDate())

		group by case
			when c.browserName like '%msie 7%' then 'MSIE 7.x'
			when c.browserName like '%msie 6%' then 'MSIE 6.x'
			when c.browserName like '%msie 5%' then 'MSIE 5.x'
			when c.browserName like '%blackberry%' then 'Blackberry'
			when c.browserName like '%iphone%' then 'IPhone'
			when c.browserName like '%ipad%' then 'IPad'
			when c.browserName like '%firefox%' then 'FireFox'
			when c.browserName like '%safari%' then 'Safari'
			when c.browserName like '%netscape%' then 'Netscape'
			when c.browserName like '%mozilla%' then 'Mozilla'
			when c.browserName like '%Opera%' then 'Opera'
			when c.browserName like '%crawler%' or c.browserName like '%bot%' or c.browserName like '%baidu%' or c.browserName like '%spider%' then 'Bot'
			when charindex('/', c.browserName) > 0 then left(c.browserName, charindex('/', c.browserName) - 1)
			else c.browserName end
		having sum(uniques) > 50
		order by requests desc

end
