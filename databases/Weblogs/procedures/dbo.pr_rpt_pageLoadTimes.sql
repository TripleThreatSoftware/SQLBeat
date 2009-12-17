ALTER procedure [dbo].[pr_rpt_pageLoadTimes] (@cSiteName varchar(100) = null)
as
begin

	select
		top 100
		friendlyName, ukey_uriStem,
		sum(numRequests) as numRequests,
		avg(pageLoadTime) as pageLoadTime_avg,
		max(pageLoadTime) as pageLoadTime_max
		into #results
		from mart_page_byday a (nolock)
		join dm_sites b (nolock) on a.ukey_site = b.ukey
			and (b.friendlyName = @cSiteName or isnull(@cSiteName, '') = '')
		where a.ymd >= dateAdd(week, -2, getDate())
		group by b.friendlyName, ukey_uriStem
		having avg(pageLoadTime) > 500
		order by avg(pageLoadTime) desc

	select a.friendlyName, c.uriStem, a.numRequests, a.pageLoadTime_avg, a.pageLoadTime_max
		from #results a
		join dm_uriStem c (nolock) on a.ukey_uriStem = c.ukey
		order by a.friendlyName, numRequests desc

	drop table #results
end
