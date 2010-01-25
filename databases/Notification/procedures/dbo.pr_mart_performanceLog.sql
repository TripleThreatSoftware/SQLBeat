SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[pr_mart_performanceLog]
as
begin
	declare @dStartDate dateTime
	if datePart(hour, getDate()) >= 3
		set @dStartDate = convert(varchar(10), getDate(), 120)
	else
		set @dStartDate = convert(varchar(10), dateAdd(day, -1, getDate()), 120)

	select
		ukey_server,
		convert(dateTime, convert(varchar(10), ymd, 120)) as ymd,
		ukey_object, ukey_counter, instanceName,
		min(counterValue) as minValue,
		max(counterValue) as maxValue,
		avg(counterValue) as avgValue
		into #martPerformanceLog
		from performanceLog (nolock)
		where runStamp >= dbo.fn_returnRunstamp(@dStartDate)
		group by ukey_server, convert(varchar(10), ymd, 120), ukey_object, ukey_counter, instanceName

	create clustered index ix_tmp_martPerformanceLog on #martPerformanceLog (ymd, ukey_server, ukey_object, ukey_counter, instanceName) with fillfactor = 100

	delete mart_performanceLog_byDay with (tablock)
		from mart_performanceLog_byDay a
		join #martPerformanceLog b on a.ukey_server = b.ukey_server
			and a.ukey_object = b.ukey_object
			and a.ukey_counter = b.ukey_counter
			and a.instanceName = b.instanceName
			and a.ymd = b.ymd

	insert into mart_performanceLog_byDay (ukey_server, ymd, ukey_object, ukey_counter, instanceName, minValue, maxValue, avgValue)
	select *
		from #martPerformanceLog

	drop table #martPerformanceLog
end
