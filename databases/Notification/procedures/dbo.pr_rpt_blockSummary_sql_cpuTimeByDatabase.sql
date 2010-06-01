SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockSummary_sql_activeConnections '2s4zlb555jayq223jisrkt3n'

-- insert into dm_blocks (blockTitle, blockSummary, blockData) values ('SQL Active Connections', 'pr_rpt_blockSummary_sql_activeConnections', '')

create procedure [dbo].[pr_rpt_blockSummary_sql_cpuTimeByDatabase] (@cMachineID varchar(100))
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
		dbName as setName,
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
		cpuTime as axis_y

		from notification.dbo.mart_database_byHour a (nolock)
		join notification.dbo.dm_servers b on a.serverName = b.servername
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where dateAdd(hour, ymd_hour, a.ymd) >= @dStartDate
--			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(cpuTime) desc)
		order by dbName, a.ymd, ymd_hour

	exec pr_generateGoogleChartsRequest @nWidth=450, @nHeight=150, @bRelativeToTotal = 0, @bShowTitle = 1, @cTitle = 'CPU Time by Database', @cGraphURL = @cGraphURL OUTPUT

	drop table #dataValues

	--******************************************************************************
	select
		@cStatusClass as statusClass,
		@cStatusMessage as statusMessage,
		@cGraphURL as graphURL

end
