-- ================================================================================================
-- Notification.dbo.pr_watchSQLConnections
--
-- Alerts when a connection matches the login, host name, database or program name criteria in the
-- watchedConnections table. Job: "Monitor for watched connections".
-- ================================================================================================
/****** Object:  StoredProcedure [dbo].[pr_watchSQLConnections]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from processLog (nolock) where servername = 'etl01' and ymd >= '2021-01-22 13:34:00.000' and login = 'sa' order by ymd


-- ALTER  table watchedConnections (ukey int identity, alertEmail varchar(200),
-- 	login varchar(100), hostname varchar(100), dbName varchar(100), programName varchar(100), serverName varchar(200))
-- insert into watchedConnections (hostname, login, serverName, alertEmail) values ('webtests', 'atm', 'sqlserver\instance4', 'dba@example.com')

CREATE  procedure [dbo].[pr_watchSQLConnections]
as
begin

	declare @nThisUkey int
	declare @cSubject varchar(200)
	declare @cMessage varchar(2000)
	declare @cThisEmail varchar(200)

	--if not exists (select top 1 id from sysobjects where name = 'ignoreConnections')
	--	create table ignoreConnections (ukey int identity, ymd dateTime default getDate(), computerName varchar(500), servername varchar(500), login varchar(500))

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
	select login, hostname, dbname, servername, programname, max(lastBatchTime) as ymd, max(bufferContents) as bufferContents, max(command) as command
		into #processes
		-- select *
		from processLog (nolock)
		where ymd >= dateadd(hour, -2, getDate())
			and not servername in (@@SERVERNAME)
			and not (status = 'background' and spid <= 70 and hostname = '' and programname = '')
			and not command in ('BRKR TASK', 'BRKR EVENT HNDLR', 'USE DATABASE', 'TASK MANAGER', 'PARALLEL REDO TASK', 'TEMPORAL_HK_FLUSH', 'TEMPORAL_CCI_RETENTION', 'BUFFER POOL PARALLEL TASK')
			and not login in ('NT Service\SQLTelemetry', 'NT SERVICE\SQLSERVERAGENT', '.\sqlservice', 'web02\sqlservice')
			and not spid <= 55
			and not (dbName = 'SimpleDance' and login = 'simpledance')
			and not (hostname = 'web02' and login in ('web02\administrator', 'web02\rmartin', 'web02\jbuchsbaum'))
			and not (hostname = 'joshua-laptop' and login in ('itchycody', 'jbuchsbaum', 'smrt_sandbox'))
			and not (hostname in ('HPDRAGONFLYG4', 'MEDIACENTER01') and login = 'sa')
			and not (hostname in ('WEB02', 'MacBook-Air', 'MacBookPro', 'Joshua-Laptop') and login in ('ItchyCody', 'ShopDAPWeb', 'shopware_svc', 'IdentityWidgetUser', 'itchycody_dashboard_read', 'itchycody_dashboard_write', 'smrt_sandbox'))
			and not (login = 'SQLBeat' and hostname = 'WEB02' and buffercontents like '%pr_generateTrialEmail%')
		group by login, hostname, dbname, servername, programname


	insert into notificationLog_stage (ymd, subject, message, severity, serverName)
	select ymd,
		'Unexpected activity. User: ' + login + ' from ' + hostname + ' (' + isnull(rtrim(programName), 'N/A') + ' / ' + isnull(rtrim(command), 'N/A') + ') at ' + convert(varchar(20), ymd) + '.',
		'Unexpected activity. User: ' + login + ' from ' + hostname + ' (' + isnull(rtrim(programName), 'N/A') + ' / ' + isnull(rtrim(command), 'N/A') + ') at ' + convert(varchar(20), ymd) + '.'+char(13)+isnull(bufferContents, ''),
		2,
		servername
		from #processes

	drop table #processes
end
GO
