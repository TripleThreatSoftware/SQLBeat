/****** Object:  StoredProcedure [dbo].[pr_rpt_userAgents_browsers]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_userAgents_browsers 'AppDb'
-- exec weblogs..pr_rpt_userAgents_browsers 'AppDb'
-- select * from dm_sites
-- select * from dm_userAgent where browserName like '%safari%' and userAgent not like '%htc%safari%' and userAgent not like '%blackberry%safari%' and userAgent not like '%droid%safari%' and userAgent not like '%iphone%safari%' and userAgent not like '%ipad%safari%' and userAgent not like '%chrome%safari%' order by dateAdded desc
-- select * from dm_userAgent where useragent like '%trident%rv%11%' order by dateAdded desc

CREATE procedure [dbo].[pr_rpt_userAgents_browsers] (@cSiteName varchar(100))
as
begin

	select
		case
			when c.userAgent like '%trident%rv%11%' then 'MSIE 11.x'
			when c.browserName like '%msie 10%' then 'MSIE 10.x'
			when c.browserName like '%msie 9%' then 'MSIE 9.x'
			when c.browserName like '%msie 8%' then 'MSIE 8.x'
			when c.browserName like '%msie 7%' then 'MSIE 7.x'
			when c.browserName like '%msie 6%' then 'MSIE 6.x'
			when c.browserName like '%msie 5%' then 'MSIE 5.x'
			when c.userAgent like '%blackberry%' then 'Blackberry'
			when c.userAgent like '%wOS%' then 'wOS'
			when c.browserName like '%firefox%' then 'FireFox'

			when c.userAgent like '%droid%safari%' then 'Safari/Android'
			when c.userAgent like '%iphone%safari%' then 'Safari/iPhone'
			when c.userAgent like '%ipad%safari%' then 'Safari/iPad'
			when c.userAgent like '%chrome%safari%' then 'Safari/Chrome'
			when c.userAgent like '%htc%safari%' then 'Safari/HTC'
			when c.userAgent like '%blackberry%safari%' then 'Safari/Blackberry'

			when c.userAgent like '%safari%imac%' then 'Safari/iMac'
			when c.userAgent like '%safari%macbookpro%' then 'Safari/MacBookPro'
			when c.userAgent like '%safari%macpro%' then 'Safari/MacPro'
			when c.userAgent like '%safari%macbookair%' then 'Safari/MacBookAir'

			when c.userAgent like '%nokia%safari%' then 'Safari/Nokia'

			when c.browserName like '%safari%' then 'Safari/Other'

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
			when c.userAgent like '%trident%rv%11%' then 'MSIE 11.x'
			when c.browserName like '%msie 10%' then 'MSIE 10.x'
			when c.browserName like '%msie 9%' then 'MSIE 9.x'
			when c.browserName like '%msie 8%' then 'MSIE 8.x'
			when c.browserName like '%msie 7%' then 'MSIE 7.x'
			when c.browserName like '%msie 6%' then 'MSIE 6.x'
			when c.browserName like '%msie 5%' then 'MSIE 5.x'
			when c.userAgent like '%blackberry%' then 'Blackberry'
			when c.userAgent like '%wOS%' then 'wOS'
			when c.browserName like '%firefox%' then 'FireFox'

			when c.userAgent like '%droid%safari%' then 'Safari/Android'
			when c.userAgent like '%iphone%safari%' then 'Safari/iPhone'
			when c.userAgent like '%ipad%safari%' then 'Safari/iPad'
			when c.userAgent like '%chrome%safari%' then 'Safari/Chrome'
			when c.userAgent like '%htc%safari%' then 'Safari/HTC'
			when c.userAgent like '%blackberry%safari%' then 'Safari/Blackberry'

			when c.userAgent like '%safari%imac%' then 'Safari/iMac'
			when c.userAgent like '%safari%macbookpro%' then 'Safari/MacBookPro'
			when c.userAgent like '%safari%macpro%' then 'Safari/MacPro'
			when c.userAgent like '%safari%macbookair%' then 'Safari/MacBookAir'

			when c.userAgent like '%nokia%safari%' then 'Safari/Nokia'

			when c.browserName like '%safari%' then 'Safari/Other'

			when c.browserName like '%netscape%' then 'Netscape'
			when c.browserName like '%mozilla%' then 'Mozilla'
			when c.browserName like '%Opera%' then 'Opera'
			when c.browserName like '%crawler%' or c.browserName like '%bot%' or c.browserName like '%baidu%' or c.browserName like '%spider%' then 'Bot'
			when charindex('/', c.browserName) > 0 then left(c.browserName, charindex('/', c.browserName) - 1)
			else c.browserName end
		having sum(uniques) > 50
		order by requests desc

end
GO
