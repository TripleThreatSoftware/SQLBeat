SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockSummary_sql_activeConnections '2s4zlb555jayq223jisrkt3n'

-- insert into dm_blocks (blockTitle, blockSummary, blockData) values ('SQL Active Connections', 'pr_rpt_blockSummary_sql_activeConnections', '')

create procedure [dbo].[pr_rpt_blockSummary_sql_pageLifeExpectancy] (@cMachineID varchar(100))
as
begin
	declare @cGraphURL varchar(8000)
	declare @cStatusClass varchar(200)
	declare @cStatusMessage varchar(500)

	set @cStatusClass = 'Status_Good'
	set @cStatusMessage = 'Good'
	set @cGraphURL = ''

	declare @nUkeyCounter int
	declare @nUkeyObject int

	set @nUkeyCounter = (select top 1 ukey from notification.dbo.dm_performanceCounters where counterName = 'Page life expectancy')
	set @nUkeyObject = (select top 1 ukey from notification.dbo.dm_performanceObjects where objectName = 'SQLServer:Buffer Manager')

	--******************************************************************************

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Page Life Expectancy',
		c.serverName,
		right(convert(varchar(16), min(a.ymd), 120), 5) as ymd,
		avg(a.counterValue) as pageLifeExpectancy_avg
		from notification.dbo.performanceLog a (nolock)
		join serverSelection b on a.ukey_server = b.ukey_server
			and b.machineID = @cMachineID
		join notification.dbo.dm_servers c (nolock) on b.ukey_server = c.ukey
		where ukey_counter = @nUkeyCounter
			and ukey_object = @nUkeyObject
			and a.ymd >= dateAdd(hour, -24, getDate())
		group by c.serverName,convert(varchar(10), a.ymd, 120), datePart(hour, a.ymd), datePart(minute, a.ymd) / 15
		order by c.serverName,min(a.ymd)

	exec pr_generateGoogleChartsRequest @nWidth=450, @nHeight=150, @bRelativeToTotal = 0, @bShowTitle = 1, @cTitle = 'Page Life Expectancy', @cGraphURL = @cGraphURL OUTPUT

	drop table #dataValues

	--******************************************************************************
	select
		@cStatusClass as statusClass,
		@cStatusMessage as statusMessage,
		@cGraphURL as graphURL

end
