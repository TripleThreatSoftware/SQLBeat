create procedure [dbo].[pr_rpt_sqlCPUWaits] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	select 'CPU ' + convert(varchar(20), cpuNumber) as subkeyName, numTasksWaiting, ymd
		from deepSQLStats_cputasks (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd <= @dEndDate
			and numTasksWaiting > 0
		order by ymd, subkeyName



end
