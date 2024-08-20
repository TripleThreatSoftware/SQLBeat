USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_watchSQLConnections]    Script Date: 8/20/2024 3:29:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- select * from processLog (nolock) where servername = 'etl01' and ymd >= '2021-01-22 13:34:00.000' and login = 'sa' order by ymd


-- ALTER  table watchedConnections (ukey int identity, alertEmail varchar(200),
-- 	login varchar(100), hostname varchar(100), dbName varchar(100), programName varchar(100), serverName varchar(200))
-- insert into watchedConnections (hostname, login, serverName, alertEmail) values ('webtests', 'atm', 'sqlserver\instance4', 'dba@example.com')

ALTER  procedure [dbo].[pr_watchSQLConnections]
as
begin

	declare @nThisUkey int
	declare @cSubject varchar(200)
	declare @cMessage varchar(2000)
	declare @cThisEmail varchar(200)

	create table #messages (ukey int identity, subject varchar(200), message varchar(2000), serverName varchar(200), alertEmail varchar(200))

	insert into #messages (subject, message, serverName, alertEmail)
	select distinct
		'SQL Automated Alerts : Watched connection detected on ' + b.serverName as subject,
		left('A watched connection was detected on ' + b.serverName + char(13) + char(13) +
--			'Detected Time : ' + rtrim(ltrim(isnull(convert(varchar(50), a.ymd), 'N/A'))) + char(13) +
			'SPID          : ' + rtrim(ltrim(isnull(convert(varchar(20), a.spid), 'N/A'))) + char(13) +
			'Login         : ' + rtrim(ltrim(isnull(a.login, 'N/A'))) + char(13) +
			'Host          : ' + rtrim(ltrim(isnull(a.hostname, 'N/A'))) + char(13) +
			'Database      : ' + rtrim(ltrim(isnull(a.dbname, 'N/A'))) + char(13) +
			'CPU Time      : ' + rtrim(ltrim(isnull(convert(varchar(20), a.cpuTime), 'N/A'))) + char(13) +
			'Disk IO       : ' + rtrim(ltrim(isnull(convert(varchar(20), a.diskio), 'N/A'))) + char(13) +
			'Program       : ' + rtrim(ltrim(isnull(a.programName, 'N/A'))) + char(13) +
			'MAC Address   : ' + rtrim(ltrim(isnull(a.net_address, 'N/A'))) + char(13) +
			'Login Time    : ' + rtrim(ltrim(isnull(convert(varchar(50), a.login_time), 'N/A'))) + char(13) +
			'Last Batch    : ' + rtrim(ltrim(isnull(convert(varchar(50), a.lastBatchTime), 'N/A'))) + char(13) +
			'Command       : (' + rtrim(ltrim(isnull(a.command, 'N/A'))) + ')' + rtrim(ltrim(a.bufferContents)) + char(13)
			, 2000) as message,
		a.serverName,
		b.alertEmail
		from processLog a (nolock)
		join watchedConnections b (nolock) on (isnull(b.login, '') = '' or (isnull(b.login, '') <> '' and isnull(a.login, '') = b.login))
			and (isnull(b.hostname, '') = '' or (isnull(b.hostname, '') is not null and isnull(a.hostname, '') = b.hostname))
			and (isnull(b.dbname, '') = '' or (isnull(b.dbname, '') is not null and isnull(a.dbname, '') = b.dbname))
			and (isnull(b.programName, '') = '' or (isnull(b.programName, '') is not null and isnull(a.programName, '') like '%' + b.programName + '%'))
		where a.ymd >= dateAdd(hour, -3, getDate())
--		group by b.serverName, a.login, a.hostname, a.dbname, a.cputime, a.diskio, a.programname, a.net_address, a.login_time, a.lastBatchTime, a.command, a.bufferContents

	delete a
		from #messages a
		join notificationLog b (nolock) on a.subject = b.subject
			and a.message = b.message
			and a.serverName = b.serverName
			and b.messageSent = 1
			and b.messageSentDate >= dateAdd(hour, -6, getDate())

	insert into notificationLog (subject, message, severity, serverName, messageSent, messageSentDate)
	select subject, message, 1 as severity, serverName, 1 as messageSent, getDate() as messageSentDate
		from #messages

	set @nThisUkey = 0

	while exists (select top 1 ukey from #messages where ukey > @nThisUkey order by ukey)
	begin
		select top 1 @nThisUkey = ukey,
			@cSubject = subject,
			@cMessage = message,
			@cThisEmail = alertEmail
			from #messages
			where ukey > @nThisUkey
			order by ukey

		exec pr_sendMessage '', @cThisEmail, @cSubject, @cMessage
	end

	drop table #messages

	-- *******************************************************************************************************************************************************************************
	-- *******************************************************************************************************************************************************************************



	-- drop table #processes
	-- select * from #processes
	select login, hostname, dbname, servername, programname, max(lastBatchTime) as ymd, max(bufferContents) as bufferContents
		into #processes
		-- select *
		from processLog (nolock)
		where ymd >= dateadd(hour, -2, getDate())
			and not servername in (@@SERVERNAME)
			and not (status = 'background' and spid <= 70 and hostname = '' and programname = '')
			and not command in ('BRKR TASK', 'BRKR EVENT HNDLR', 'USE DATABASE', 'TASK MANAGER')
			and not login in ('NT Service\SQLTelemetry', 'NT SERVICE\SQLSERVERAGENT')
			and not spid <= 55
			and not (dbName = 'SimpleDance' and login = 'simpledance')
			and not hostname = 'HPDRAGONFLYG4'
		group by login, hostname, dbname, servername, programname


	insert into notificationLog_stage (ymd, subject, message, severity, serverName)
	select ymd,
		'Unexpected activity. User: ' + login + ' from ' + hostname + ' (' + isnull(rtrim(programName), 'N/A') + ') at ' + convert(varchar(20), ymd) + '.',
		'Unexpected activity. User: ' + login + ' from ' + hostname + ' (' + isnull(rtrim(programName), 'N/A') + ') at ' + convert(varchar(20), ymd) + '.'+char(13)+isnull(bufferContents, ''),
		2,
		servername
		from #processes

	drop table #processes
end
