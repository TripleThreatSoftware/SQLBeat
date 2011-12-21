ALTER procedure [dbo].[pr_rpt_processorLoadOnDay] (@nUkeyServer int = 0, @dDate dateTime, @cServerName varchar(100) = '')
as
begin

--declare @nUkeyServer int
--declare @dDate dateTime
--set @nUkeyServer = (select top 1 ukey from notification..dm_servers where servername = 'prooradb01')
--set @dDate = '2010-02-10'

	if ISNULL(@nUkeyServer, 0) = 0
		set @nUkeyServer = (select top 1 ukey from notification..dm_servers where servername = @cServerName)

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Avg', 'Avg',
		left(right(convert(varchar(20), min(ymd), 120), 8), 5) as ymd,
		avg(processorLoad) as processorLoad

		from processorLoadLog a (nolock)
		where ukey_server = @nUkeyServer
			and ymd >= @dDate
			and ymd < dateAdd(day, 1, @dDate)
		group by datePart(hour, ymd), datePart(minute, ymd) / 15
		order by min(ymd)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Max', 'Max',
		left(right(convert(varchar(20), min(ymd), 120), 8), 5) as ymd,
		max(processorLoad) as processorLoad

		from processorLoadLog a (nolock)
		where ukey_server = @nUkeyServer
			and ymd >= @dDate
			and ymd < dateAdd(day, 1, @dDate)
		group by datePart(hour, ymd), datePart(minute, ymd) / 15
		order by min(ymd)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
	drop table #dataValues
end
