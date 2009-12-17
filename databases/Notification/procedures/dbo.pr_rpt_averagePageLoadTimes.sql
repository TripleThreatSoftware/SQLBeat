alter procedure [dbo].[pr_rpt_averagePageLoadTimes] (@cSiteName varchar(100) = null)
as
begin

	select
		'Average load time' as seriesName,
		'Average load time' as setName,
		convert(varchar(10), ymd, 120) as axis_x,
		avg(pageLoadTime) as axis_y,
		identity(int) as sortOrder
		into #dataValues
		from mart_page_byday a (nolock)
		join dm_sites b (nolock) on a.ukey_site = b.ukey
			and (b.friendlyName = @cSiteName or isnull(@cSiteName, '') = '')
		where a.ymd >= dateAdd(month, -2, getDate())
		group by ymd
		order by ymd

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	drop table #dataValues
end
