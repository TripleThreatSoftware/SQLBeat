USE [Mart]
GO
/****** Object:  StoredProcedure [dbo].[pr_graph_overallTransactionVolume]    Script Date: 01/08/2009 08:40:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_graph_overallTransactionVolume]
as
begin
	declare @dToday dateTime
	set @dToday = convert(varchar(10), dateAdd(day, -1, getDate()), 120)

	select
		'Overall Transaction Volume' as setName,
		'Overall' as seriesName,
		right(convert(varchar(10), min(ymd), 120), 5) as axis_x,
		sum(numTransactions) as axis_y,
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
