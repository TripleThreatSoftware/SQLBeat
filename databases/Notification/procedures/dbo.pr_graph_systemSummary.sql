create procedure [dbo].[pr_graph_systemSummary]
as
begin
	select
		'System Summary' as setName,
		'Merchants' as seriesName,
		right(convert(varchar(10), min(ymd), 120), 5) as axis_x,
		sum(numMerchants) as axis_y,
		identity(int) as sortOrder
		into #dataValues
		from mart_transactionVolume_byday
		where ymd >= dateAdd(day, -7*52, @dToday)
			and ymd <= @dToday
		group by dateDiff(day, ymd, @dToday) / (7)
		order by dateDiff(day, ymd, @dToday) / (7) desc

	delete from #dataValues where sortOrder = 1

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

	drop table #dataValues
end
