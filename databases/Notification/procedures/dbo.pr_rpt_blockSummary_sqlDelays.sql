SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockSummary_sqlDelays '2s4zlb555jayq223jisrkt3n'

alter procedure [dbo].[pr_rpt_blockSummary_sqlDelays] (@cMachineID varchar(100))
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
		'Blocking' as setName,
		'Blocking' as seriesName,
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
		count(*) as axis_y
		from notification..processLog a (nolock)
		join notification..dm_servers b (nolock) on a.serverName = b.serverName
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where a.ymd >= dateAdd(hour, -12, getDate())
			and a.isBlocked = 1
		group by datePart(hour, a.ymd)
		order by datePart(hour, a.ymd)

	select datepart(hour, a.ymd) as ymd_hour, lastWaitType, count(*) as numSPIDs
		into #waiting
		from notification..processLog a (nolock)
		join notification..dm_servers b (nolock) on a.serverName = b.serverName
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where a.ymd >= dateAdd(hour, -12, getDate())
			and a.isBlocked = 0
			and a.command <> 'Awaiting Command'
		group by datePart(hour, a.ymd), lastWaitType
		order by datePart(hour, a.ymd), lastWaitType

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'OLEDB' as setName,
		'OLEDB' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
			case
				when ymd_hour >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		numSPIDs as axis_y
		from #waiting
		where lastWaitType = 'OLEDB'



	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Network' as setName,
		'Network' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
			case
				when ymd_hour >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		numSPIDs as axis_y
		from #waiting
		where lastWaitType = 'ASYNC_NETWORK_IO'


	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'CPU' as setName,
		'CPU' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
			case
				when ymd_hour >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		numSPIDs as axis_y
		from #waiting
		where lastWaitType = 'SOS_SCHEDULER_YIELD'


	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Other' as setName,
		'Other' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
			case
				when ymd_hour >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		sum(numSPIDs) as axis_y
		from #waiting
		where lastWaitType not in ('SOS_SCHEDULER_YIELD', 'OLEDB', 'ASYNC_NETWORK_IO', '')
		group by ymd_hour


	exec pr_generateGoogleChartsRequest @nWidth=450, @nHeight=150, @bAbsoluteYAxis = 1, @bShowTitle = 1, @cTitle = 'Sources of Delay', @cGraphURL = @cGraphURL OUTPUT, @bLeaveAllSets = 1


	drop table #dataValues
	drop table #waiting

	--******************************************************************************
	select
		@cStatusClass as statusClass,
		@cStatusMessage as statusMessage,
		@cGraphURL as graphURL

end
