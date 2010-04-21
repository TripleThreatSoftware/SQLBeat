SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockSummary_iis '2s4zlb555jayq223jisrkt3n'

alter procedure [dbo].[pr_rpt_blockSummary_iis] (@cMachineID varchar(100))
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
	create table #output (graphURL varchar(8000))

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		a.serverName, a.serverName,
		right(convert(varchar(10), a.ymd, 120), 5) as axis_x,
		count(*) as axis_y
		from notification.dbo.notificationLog a (nolock)
		join notification..dm_servers b (nolock) on a.serverName = b.serverName
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where a.severity in (1,2)
			and a.message like '%an unhandled exception has occurred%'
		group by a.serverName, convert(varchar(10), a.ymd, 120)
		order by a.serverName, convert(varchar(10), a.ymd, 120)

	exec pr_generateGoogleChartsRequest @nWidth=450, @nHeight=150, @bAbsoluteYAxis = 1, @bShowTitle = 1, @cTitle = 'Exceptions', @cGraphURL = @cGraphURL OUTPUT, @bLeaveAllSets = 1

	if (select count(*) from #dataValues where axis_y > 20) > 0
	begin
		set @cStatusClass = 'Status_Bad'
		set @cStatusMessage = 'Exceptions generated for ' + convert(varchar(20), (select convert(int, sum(axis_y)) from #dataValues where axis_y > 0)) + ' calls!'
	end
	else
	if (select count(*) from #dataValues where axis_y > 1) > 5
	begin
		set @cStatusClass = 'Status_Warning'
		set @cStatusMessage = 'Exceptions generated for ' + convert(varchar(20), (select convert(int, sum(axis_y)) from #dataValues where axis_y > 0)) + ' calls!'
	end

	drop table #output
	drop table #dataValues

	--******************************************************************************
	select
		@cStatusClass as statusClass,
		@cStatusMessage as statusMessage,
		@cGraphURL as graphURL

end
