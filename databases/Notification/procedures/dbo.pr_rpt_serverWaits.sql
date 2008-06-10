SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_serverWaits 'funmssql02', null, null
ALTER procedure [dbo].[pr_rpt_serverWaits] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
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
			from deepSQLStats (nolock)
			where serverName = @cServerName
				and keyName = 'CPU Scheduler'
				and ymd >= @dStartDate
				and ymd <= @dEndDate
		)

	select subkeyName, keyValue, ymd
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and keyName = 'Wait Statistics'
			and ymd = @dLatestRun_waitStats
	union
	select 'CPU ' + subkeyName as subkeyName, keyValue, ymd
		from deepSQLStats (nolock)
		where serverName = @cServerName
			and keyName = 'CPU Scheduler'
			and ymd = @dLatestRun_cpuScheduler
		order by subkeyName



end
