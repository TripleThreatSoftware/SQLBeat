USE [Weblogs]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_averagePageLoadTimes]    Script Date: 12/09/2011 16:51:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_averagePageLoadTimes 'AppDb', 30
ALTER procedure [dbo].[pr_rpt_averagePageLoadTimes] (@cSiteName varchar(100) = null, @nNumDays int = 60)
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
		where a.ymd >= dateAdd(day, -@nNumDays, getDate())
		group by ymd
		order by ymd

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	drop table #dataValues
end
