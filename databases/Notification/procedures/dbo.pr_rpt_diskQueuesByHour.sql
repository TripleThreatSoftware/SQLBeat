-- exec pr_rpt_diskQueuesByHour 'ttssvr'
CREATE procedure [dbo].[pr_rpt_diskQueuesByHour] (@cServerName varchar(100))
as
begin
--	declare @cServerName varchar(100)
--	set @cServerName = 'mssql-ny'
	set nocount on

	declare @dStartDate dateTime
	declare @dEndDate dateTime
	declare @nCounter int

	set @dStartDate = isnull(@dStartDate, dateAdd(day, -21, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @results table (ymd dateTime, [hour] int, numWaiting int)
	set @nCounter = 0
	while dateAdd(hour, @nCounter, @dStartDate) < @dEndDate
	begin
		insert into @results (ymd, [hour]) values (convert(varchar(10), dateAdd(hour, @nCounter, @dStartDate), 120), datePart(hour, dateAdd(hour, @nCounter, @dStartDate)))
		set @nCounter = @nCounter + 1
	end

	set nocount on

	update @results
		set numWaiting = b.numRequests
		from @results a
		join (
			select
				convert(varchar(10), ymd, 120) as ymd,
				datePart(hour, ymd) as [hour],
				sum(convert(int, substring(keyvalue, 1, charindex(' ', keyValue)))) as numRequests
				from deepSQLStats (nolock)
				where subkeyName like '%disk io waiting%'
					and serverName = @cServername
					and ymd >= @dStartDate
					and ymd <= @dEndDate
				group by convert(varchar(10), ymd, 120), datePart(hour, ymd)
			) b on a.ymd = b.ymd
				and a.[hour] = b.[hour]

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Disk Waiting by Hour' as setName,
		'Disk Waiting by Hour' as seriesName,
		[hour],
		sum(numWaiting) as numWaiting
		from @results
		group by [hour]
		order by [hour]

	exec pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1, @bLeavePeaks = 1

	drop table #dataValues

end



GO
