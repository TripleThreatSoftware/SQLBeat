/****** Object:  StoredProcedure [dbo].[pr_graph_pageLifeExpectancy]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_pageLifeExpectancy '10.3.10.110'
create procedure [dbo].[pr_graph_pageLifeExpectancy] (@cServerName varchar(100))
as
begin

	--declare @cServerName varchar(100)
	--set @cServerName = '10.3.10.110'

	declare @nUkeyCounter int
	declare @nUkeyObject int
	declare @nUkeyServer int

	set @nUkeyCounter = (select top 1 ukey from dm_performanceCounters where counterName = 'Page life expectancy')
	set @nUkeyObject = (select top 1 ukey from dm_performanceObjects where objectName = 'SQLServer:Buffer Manager')
	set @nUkeyServer = (select top 1 ukey from dm_servers where servername = @cServerName)

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues
	select
		'Page Life Expectancy',
		'Page Life Expectancy',
		right(convert(varchar(16), min(ymd), 120), 5) as ymd,
--		min(counterValue) as pageLifeExpectancy_min,
		avg(counterValue) as pageLifeExpectancy_avg
		from performanceLog a (nolock)
		where ukey_counter = @nUkeyCounter
			and ukey_object = @nUkeyObject
			and ukey_server = @nUkeyServer
			and ymd >= dateAdd(hour, -24, getDate())
		group by convert(varchar(10), ymd, 120), datePart(hour, ymd), datePart(minute, ymd) / 15
		order by min(ymd)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1

end
GO
