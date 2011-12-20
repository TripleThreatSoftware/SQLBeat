USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_eventLog]    Script Date: 12/20/2011 10:12:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from dm_servers where servername = 'appcln02'
--GO
--select *
--	from eventLog
--	where message not like '%login succeeded%'
--			and [type] not in ('Information', 'Warning')
--			and sourceName not in ('TermServDevices', 'PrintSpooler', 'Print', 'W32Time', 'SceCli', 'AutoEnrollment', 'MsGina', 'Microsoft-Windows-TerminalServices-Printers')
--			and message not like '%web proxy auto-discovery%'
--			and message <> ''

-- exec pr_rpt_eventLog 0, 336, 'devmssql02'
ALTER procedure [dbo].[pr_rpt_eventLog] (@nUkeyServer int = 0, @nNumHours int = 48, @cServerName varchar(200) = '')
as
begin
	declare @cComputerName varchar(200)
	declare @dMaxViewData dateTime
	if isnull(@cServerName, '') = ''
		set @cComputerName = (select top 1 serverName from dm_servers where ukey = @nUkeyServer)
	else
		set @cComputerName = @cServerName

--	set @dMaxViewData = (select max(timeWritten) from v_eventLog_all where computerName = @cComputerName)

	declare @results table (serverName varchar(200), timeWritten dateTime, sourceName varchar(1000), category varchar(1000), message varchar(8000), auser varchar(500))

	insert into @results
	select
		computerName as serverName, timeWritten, sourceName, category, message, auser
		from eventLog (nolock)
		where timeWritten >= dateAdd(hour, -@nNumHours, getDate())
			and (computerName = @cComputerName or isnull(@cComputerName, '') = '')
			and message not like '%login succeeded%'
			and [type] not in ('Information', 'Warning')
			and sourceName not in ('TermServDevices', 'PrintSpooler', 'Print', 'W32Time', 'SceCli', 'AutoEnrollment', 'MsGina', 'Microsoft-Windows-TerminalServices-Printers')
			and message not like '%web proxy auto-discovery%'
			and message <> ''
--			and timeWritten > @dMaxViewData

	--insert into @results
	--select
	--	computerName as serverName, timeWritten, sourceName, category, message, auser
	--	from v_eventLog_all (nolock)
	--	where timeWritten >= dateAdd(hour, -@nNumHours, getDate())
	--		and (computerName = @cComputerName or isnull(@cComputerName, '') = '')
	--		and message not like '%login succeeded%'
	--		and [type] not in ('Information', 'Warning')
	--		and sourceName not in ('TermServDevices', 'PrintSpooler', 'Print', 'W32Time', 'SceCli', 'AutoEnrollment', 'MsGina', 'Microsoft-Windows-TerminalServices-Printers')
	--		and message not like '%web proxy auto-discovery%'
	--		and message <> ''
	--		and timeWritten < @dMaxViewData

	select *
		from @results
		order by timeWritten desc

end
