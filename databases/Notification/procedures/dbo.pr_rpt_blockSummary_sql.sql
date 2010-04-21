SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockSummary_sqlPerformance '2s4zlb555jayq223jisrkt3n'

alter procedure [dbo].[pr_rpt_blockSummary_sql] (@cMachineID varchar(100))
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
		'CPUTime' as setName,
		'CPUTime' as seriesName,
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
		sum(cpuTime) as axis_y
		from notification..mart_database_byHour a (nolock)
		join notification..dm_servers b (nolock) on a.serverName = b.serverName
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= dateAdd(hour, -23, getDate())
		group by a.ymd, ymd_hour
		order by a.ymd, ymd_hour

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'DiskIO' as setName,
		'DiskIO' as seriesName,
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
		sum(diskIO) as axis_y
		from notification..mart_database_byHour a (nolock)
		join notification..dm_servers b (nolock) on a.serverName = b.serverName
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= dateAdd(hour, -23, getDate())
		group by a.ymd, ymd_hour
		order by a.ymd, ymd_hour


	exec pr_generateGoogleChartsRequest @nWidth=450, @nHeight=150, @bRelativeToTotal = 0, @bShowTitle = 1, @cTitle = 'Relative Load', @cGraphURL = @cGraphURL OUTPUT

	drop table #dataValues

	--******************************************************************************
	select
		@cStatusClass as statusClass,
		@cStatusMessage as statusMessage,
		@cGraphURL as graphURL

end
