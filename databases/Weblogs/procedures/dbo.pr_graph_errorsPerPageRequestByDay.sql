/****** Object:  StoredProcedure [dbo].[pr_graph_errorsPerPageRequestByDay]    Script Date: 12/04/2009 18:51:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_errorsPerPageRequestByDay 'PRO - DOEPublic', '2008-06-01', null
CREATE procedure [dbo].[pr_graph_errorsPerPageRequestByDay] (@cSiteName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(week, -1, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	select
		'Errors per PR' as seriesName,
		'Errors per PR' as setName,
		convert(varchar(10), ymd, 120) as axis_x,
		convert(decimal(10,2), 100 *
			case
				when sum(pageRequests) = 0
					then 0
					else
						convert(decimal(25,4),
							isnull(
								convert(decimal(10,2), sum(pageNotFoundErrors)) / convert(decimal(10,2), sum(pageRequests)),
								0.00
								)
							) end
			) as axis_y,
		identity(int) as sortOrder

		into #dataValues

		from mart_site_byday a
		join dm_sites b on a.ukey_site = b.ukey
			and b.friendlyName = @cSiteName
		where a.ymd >= @dStartDate
			and a.ymd <= @dEndDate
		group by convert(varchar(10), ymd, 120)
		order by convert(varchar(10), ymd, 120)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	drop table #dataValues
end
GO
