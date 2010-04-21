SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockSummary_websites '2s4zlb555jayq223jisrkt3n'

alter procedure [dbo].[pr_rpt_blockSummary_websites] (@cMachineID varchar(100))
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
		b.friendlyName, b.friendlyName,
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
		sum(case when a.isAvailable = 0 then 1 else 0 end) as axis_x
		from websiteMonitor.dbo.monitoredURLs_history a (nolock)
		join websiteMonitor.dbo.monitoredURLs b (nolock) on a.ukey_url = b.ukey
		where a.ymd >= dateAdd(hour, -23, getDate())
		group by b.friendlyName, datePart(hour, a.ymd)
		order by b.friendlyName, datePart(hour, a.ymd)

	exec pr_generateGoogleChartsRequest @nWidth=450, @nHeight=150, @bAbsoluteYAxis = 1, @bShowTitle = 1, @cTitle = 'URLs Down', @cGraphURL = @cGraphURL OUTPUT, @bLeaveAllSets = 1


	if (select count(*) from #dataValues where axis_y > 0) > 5
	begin
		set @cStatusClass = 'Status_Bad'
		set @cStatusMessage = 'Significant URL outage (' + convert(varchar(20), (select count(*) from #dataValues where axis_y > 0)) + ' URL-hours down)'
	end
	else
	if (select count(*) from #dataValues where axis_y > 0) > 1
	begin
		set @cStatusClass = 'Status_Warning'
		set @cStatusMessage = 'Some URLs down (' + convert(varchar(20), (select count(*) from #dataValues where axis_y > 0)) + ' URL-hours)'
	end

	drop table #dataValues

	--******************************************************************************
	select
		@cStatusClass as statusClass,
		@cStatusMessage as statusMessage,
		@cGraphURL as graphURL

end
