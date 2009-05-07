/****** Object:  StoredProcedure [dbo].[pr_rpt_serverWaits]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_serverWaits] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'funmssql02'

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	declare @dLatestRun_waitStats dateTime
	declare @dLatestRun_cpuScheduler dateTime

	set @dLatestRun_waitStats = (
		select max(ymd)
			from deepSQLStats (nolock)
			where serverName = @cServerName
				and keyName ='Wait Statistics'
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)
	set @dLatestRun_cpuScheduler = (
		select max(ymd)
			from deepSQLStats_cputasks (nolock)
			where serverName = @cServerName
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)

	select subkeyName, keyValue, ymd
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and keyName = 'Wait Statistics'
			and ymd = @dLatestRun_waitStats
	union
	select 'CPU ' + convert(varchar(20), cpuNumber) as subkeyName, convert(varchar(20), numTasksWaiting) + ' tasks waiting', ymd
		from deepSQLStats_cputasks (nolock)
		where serverName = @cServerName
			and ymd = @dLatestRun_cpuScheduler
		order by subkeyName



end
GO
