-- exec pr_rpt_averageIndividualPageLoadTimes 'AppDb'
alter procedure [dbo].[pr_rpt_averageIndividualPageLoadTimes] (@cSiteName varchar(100) = null)
as
begin

	select
		c.uriStem as seriesName,
		c.uriStem as setName,
		right(min(convert(varchar(10), ymd, 120)), 5) as axis_x,
		avg(pageLoadTime) as axis_y,
		identity(int) as sortOrder
		into #dataValues
		from mart_page_byday a (nolock)
		join dm_sites b (nolock) on a.ukey_site = b.ukey
			and (b.friendlyName = @cSiteName or isnull(@cSiteName, '') = '')
		join dm_uriStem c (nolock) on a.ukey_uriStem = c.ukey
			and c.isPage = 1
		join (
			select top 10 a.ukey_uriStem
				from mart_page_byday a (nolock)
				join dm_sites b (nolock) on a.ukey_site = b.ukey
					and (b.friendlyName = @cSiteName or isnull(@cSiteName, '') = '')
				where a.ymd >= dateAdd(week, -2, getDate())
				group by a.ukey_uriStem
				order by sum(numRequests) desc
			) d on a.ukey_uristem = d.ukey_uriStem
		where a.ymd >= dateAdd(week, -30, getDate())
		group by c.uriStem, dateParT(year, ymd), datePart(week, ymd)
		order by c.uriStem, dateParT(year, ymd), datePart(week, ymd)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	drop table #dataValues
end
