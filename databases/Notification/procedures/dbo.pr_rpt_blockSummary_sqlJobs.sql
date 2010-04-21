SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockSummary_sqlJobs '2s4zlb555jayq223jisrkt3n'

alter procedure [dbo].pr_rpt_blockSummary_sqlJobs (@cMachineID varchar(100))
as
begin
	declare @cGraphURL varchar(8000)
	declare @cStatusClass varchar(200)
	declare @cStatusMessage varchar(500)

	set @cStatusClass = 'Status_Good'
	set @cStatusMessage = 'Good'
	set @cGraphURL = ''

	--******************************************************************************

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Failed Jobs' as setName,
		'Failed Jobs' as seriesName,
		convert(varchar(2),
			case
				when datePart(hour, a.ymd) >= 13
					then datePart(hour, a.ymd) - 12
					else datePart(hour, a.ymd)
					end) +
			case
				when datePart(hour, a.ymd) >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		sum(case when a.isJobFailure = 1 then 1 else 0 end) as axis_y
		from notification..notificationLog a (nolock)
		join notification..dm_servers b (nolock) on a.serverName = b.serverName
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where a.ymd >= dateAdd(hour, -23, getDate())
		group by datePart(hour, a.ymd)
		order by datePart(hour, a.ymd)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Long Running Jobs' as setName,
		'Long Running Jobs' as seriesName,
		convert(varchar(2),
			case
				when datePart(hour, a.ymd) >= 13
					then datePart(hour, a.ymd) - 12
					else datePart(hour, a.ymd)
					end) +
			case
				when datePart(hour, a.ymd) >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		sum(case when a.isLongRunningJob = 1 then 1 else 0 end) as axis_y
		from notification..notificationLog a (nolock)
		join notification..dm_servers b (nolock) on a.serverName = b.serverName
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where a.ymd >= dateAdd(hour, -23, getDate())
		group by datePart(hour, a.ymd)
		order by datePart(hour, a.ymd)

	exec pr_generateGoogleChartsRequest @nWidth=450, @nHeight=150, @bAbsoluteYAxis = 1, @bShowTitle = 1, @cTitle = 'Job History', @cGraphURL = @cGraphURL OUTPUT, @bLeaveAllSets = 1, @bAlwaysShowLegend = 1

	if (select sum(axis_y) from #dataValues where setName = 'Failed Jobs') >= 5
	begin
		set @cStatusClass = 'Status_Bad'
		set @cStatusMessage = convert(varchar(20), (select convert(int, sum(axis_y)) from #dataValues where setName = 'Failed Jobs')) + ' failed jobs in the last 24 hours!'
	end
	else
	if (select sum(axis_y) from #dataValues where setName = 'Failed Jobs') > 0
	begin
		set @cStatusClass = 'Status_Warning'
		set @cStatusMessage = convert(varchar(20), (select convert(int, sum(axis_y)) from #dataValues where setName = 'Failed Jobs')) + ' failed jobs in the last 24 hours!'
	end

	drop table #dataValues


	--******************************************************************************
	select
		@cStatusClass as statusClass,
		@cStatusMessage as statusMessage,
		@cGraphURL as graphURL

end
