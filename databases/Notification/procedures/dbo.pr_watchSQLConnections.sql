IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_watchSQLConnections]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- ALTER  table watchedConnections (ukey int identity, alertEmail varchar(200),
-- 	login varchar(100), hostname varchar(100), dbName varchar(100), programName varchar(100), serverName varchar(200))
-- insert into watchedConnections (hostname, login, serverName, alertEmail) values (''webtests'', ''atm'', ''sqlserver\instance4'', ''dba@example.com'')

CREATE  procedure [pr_watchSQLConnections]
as
begin

	declare @nThisUkey int
	declare @cSubject varchar(200)
	declare @cMessage varchar(2000)
	declare @cThisEmail varchar(200)

	create table #messages (ukey int identity, subject varchar(200), message varchar(2000), serverName varchar(200), alertEmail varchar(200))

	insert into #messages (subject, message, serverName, alertEmail)
	select distinct
		''SQL Automated Alerts : Watched connection detected on '' + b.serverName as subject,
		left(''A watched connection was detected on '' + b.serverName + char(13) + char(13) +
--			''Detected Time : '' + rtrim(ltrim(isnull(convert(varchar(50), a.ymd), ''N/A''))) + char(13) +
			''SPID          : '' + rtrim(ltrim(isnull(convert(varchar(20), a.spid), ''N/A''))) + char(13) +
			''Login         : '' + rtrim(ltrim(isnull(a.login, ''N/A''))) + char(13) +
			''Host          : '' + rtrim(ltrim(isnull(a.hostname, ''N/A''))) + char(13) +
			''Database      : '' + rtrim(ltrim(isnull(a.dbname, ''N/A''))) + char(13) +
			''CPU Time      : '' + rtrim(ltrim(isnull(convert(varchar(20), a.cpuTime), ''N/A''))) + char(13) +
			''Disk IO       : '' + rtrim(ltrim(isnull(convert(varchar(20), a.diskio), ''N/A''))) + char(13) +
			''Program       : '' + rtrim(ltrim(isnull(a.programName, ''N/A''))) + char(13) +
			''MAC Address   : '' + rtrim(ltrim(isnull(a.net_address, ''N/A''))) + char(13) +
			''Login Time    : '' + rtrim(ltrim(isnull(convert(varchar(50), a.login_time), ''N/A''))) + char(13) +
			''Last Batch    : '' + rtrim(ltrim(isnull(convert(varchar(50), a.lastBatchTime), ''N/A''))) + char(13) +
			''Command       : ('' + rtrim(ltrim(isnull(a.command, ''N/A''))) + '')'' + rtrim(ltrim(a.bufferContents)) + char(13)
			, 2000) as message,
		a.serverName,
		b.alertEmail
		from processLog a
		join watchedConnections b on (isnull(b.login, '''') = '''' or (isnull(b.login, '''') <> '''' and isnull(a.login, '''') = b.login))
			and (isnull(b.hostname, '''') = '''' or (isnull(b.hostname, '''') is not null and isnull(a.hostname, '''') = b.hostname))
			and (isnull(b.dbname, '''') = '''' or (isnull(b.dbname, '''') is not null and isnull(a.dbname, '''') = b.dbname))
			and (isnull(b.programName, '''') = '''' or (isnull(b.programName, '''') is not null and isnull(a.programName, '''') like ''%'' + b.programName + ''%''))
		where a.ymd >= dateAdd(hour, -3, getDate())

	delete a
		from #messages a
		join notificationLog b on a.subject = b.subject
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

		exec pr_sendMessage '''', @cThisEmail, @cSubject, @cMessage
	end

	drop table #messages
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_unauthorizedProductionAccess]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'create         procedure [pr_rpt_unauthorizedProductionAccess]
as
begin
	declare @bTesting bit
	declare @cThisSubject varchar(1000)
	declare @cThisMessage varchar(8000)
	declare @nThisUkey int

	set nocount on
	set ansi_warnings off

	set @bTesting = 0
	set @cThisMessage = ''''
	set @cThisSubject = ''''

	select
		@cThisMessage = @cThisMessage +
			left(isnull(serverName, '''') + replicate('' '', 20), 20) +
			left(isnull(hostname, '''') + replicate('' '', 15), 15) +
			left(isnull(login, '''') + replicate('' '', 10), 10) +
			left(isnull(dbname, '''') + replicate('' '', 15), 15) +
			left(isnull(command, '''') + replicate('' '', 20), 20) +
			left(isnull(convert(varchar(20), lastDate, 120), '''') + replicate('' '', 20), 20) +
			left(isnull(programName, '''') + replicate('' '', 15), 15) +
			char(13)
		from (
			select serverName, hostName, login, dbname,
				case when isBlocker = 1 then ''BLOCKING'' else command end as command,
				programName,
				max(ymd) as lastDate
				from processLog
				where (serverName like ''sqlserver\%'' or serverName = ''chronicle1'' or serverName = ''rt-pricebook1'')
					and spid > 50
--					and login not like ''CORP\%''
					and ymd >= dateAdd(week, -1, getDate())
--					and hostname not in (''admin'', ''smontgomery'', ''fcallaway'', ''tmgllc'',
--						''intra1'', ''intra2'', ''LAWSONSTUDIO'', ''TASKMSTR2'')
--					and login <> ''remoteAdmin''
--					and not (hostname = ''sqlserver'' and login = ''sa'')
					and (
						(
							programName like ''%query analyzer%''
							or programName like ''%ms sqlem%''
							or programName like ''%sqlclient data provider%''
							or programName like ''%visual basic%''
							)
--						or (hostname like ''%test%'' and hostname <> ''store_test'')
						)
				group by serverName, hostname, login, case when isBlocker = 1 then ''BLOCKING'' else command end, dbname, programName
			) a
		order by hostname, login, dbname, command

	set @cThisSubject = ''SAA : Weekly Production Access Report ('' + convert(varchar(20), @@ROWCOUNT) + '' tattles)''

	set @cThisMessage = ''These accesses happened within the last week.

SERVER              HOST           LOGIN     DATABASE       COMMAND             LAST SEEN           PROGRAM
=================== ============== ========= ============== =================== =================== ==============
'' + @cThisMessage

-- 	print @cThisSubject
-- 	print @cThisMessage

	if @bTesting = 1
	begin
		set @cThisSubject = ''(TEST) '' + @cThisSubject
		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
	end
	else
	begin
		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
	end
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_outageReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_rpt_outageReport]
as
begin

	-- First, detail on the time and duration of outages in the last week
	declare @dStartDate dateTime
	declare @nThisUkey int
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	set @dStartDate = dateAdd(week, -1, convert(varchar(10), getDate(), 120))

	select serverName, ymd as outageStart
		into #outages
		from pingLog
		where isServerPingable = 0
			and ymd >= @dStartDate

	select a.serverName, min(a.outageStart) as outageStart, b.outageStop, convert(varchar(50), null) as details
		into #results
		from #outages a
		left outer join (
			select a.serverName, a.outageStart, min(b.ymd) as outageStop
				from #outages a
				join pingLog b on a.serverName = b.serverName
					and b.isServerPingable = 1
					and b.ymd > a.outageStart
				group by a.serverName, a.outageStart
			) b on a.serverName = b.serverName
				and a.outageStart = b.outageStart
		group by a.serverName, b.outageStop
		order by a.serverName, min(a.outageStart)

	select ukey_url, ymd as outageStart
		into #websiteOutages
		from websiteMonitor..monitoredURLs_history a
		where a.ymd >= @dStartDate
			and isAvailable = 0

	insert into #results (servername, outageStart, outageStop)
	select distinct c.friendlyName, min(a.outageStart) as outageStart, b.outageStop
		from #websiteOutages a
		left outer join (
			select a.ukey_url, a.outageStart, min(b.ymd) as outageStop
				from #websiteOutages a
				join websiteMonitor..monitoredURLs_history b on a.ukey_url = b.ukey_url
					and b.isAvailable = 1
					and b.ymd > a.outageStart
				group by a.ukey_url, a.outageStart
			) b on a.ukey_url = b.ukey_url
				and a.outageStart = b.outageStart
		join websiteMonitor..monitoredURLs c on a.ukey_url = c.ukey

		group by c.friendlyName, b.outageStop
		order by c.friendlyName, min(a.outageStart)

	insert into #results (servername, outageStart, outageStop, details)
	select left(substring(subject, charindex(''with '', subject) + 5, 99), charindex('' '', substring(subject, charindex(''with '', subject) + 5, 99)) - 1) as serverName,
		ymd as outageStart,
		null as outageStop,
		''Point Outage'' as details
		from notificationLog
		where
			serverName = ''2k3devseed3''
			and subject like ''%lost communication%''
			and message not like ''%transaction log%''
			and message not like ''%disk space%''
			and ymd >= @dStartDate
		order by ymd

	-- Then, uptime summary for servers that have had outages
	select a.friendlyName as serverName,
		totalPings as connectionAttempts,
		droppedPings as connectionFailures,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		latestDrop, earliestData, latestData

		into #summary

		from (
			select
				case when isnull(b.friendlyName, '''') = '''' then b.websiteURL else b.friendlyName end as friendlyName,
				min(a.ymd) as earliestData,
				max(a.ymd) as latestData,
				min(case when a.isAvailable = 0 then a.ymd else null end) as earliestDrop,
				max(case when a.isAvailable = 0 then a.ymd else null end) as latestDrop,
				max(case when a.isAvailable = 1 then a.ymd else null end) as latestSuccess,
				count(distinct case when a.isAvailable = 0 then a.ukey else null end) as droppedPings,
				count(*) as totalPings
				from websiteMonitor..monitoredURLs_history a
				join websiteMonitor..monitoredURLs b on a.ukey_url = b.ukey
					and b.isEnabled = 1
				where a.ymd >= @dStartDate
				group by case when isnull(b.friendlyName, '''') = '''' then b.websiteURL else b.friendlyName end
			) a
		where droppedPings > 0


	insert into #summary (serverName, connectionAttempts, connectionFailures, failureRate, availability, latestDrop, earliestData, latestData)
	select a.friendlyName as serverName,
		totalPings as connectionAttempts,
		droppedPings as connectionFailures,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		latestDrop, earliestData, latestData
		from (
			select
				case when isnull(a.friendlyName, '''') = '''' then a.serverName else a.friendlyName end as friendlyName,
				min(a.ymd) as earliestData,
				max(a.ymd) as latestData,
				min(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as earliestDrop,
				max(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as latestDrop,
				max(case when a.isServerPingable = 1 and a.isRouterPingable = 1 then a.ymd else null end) as latestSuccess,
				count(distinct case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ukey else null end) as droppedPings,
				count(*) as totalPings,
				avg(case when isnull(serverPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, ''time'', 1), 10), 0) else 0 end) as serverPing1,
				avg(case when isnull(serverPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, ''time'', 2), 10), 0) else 0 end) as serverPing2,
				avg(case when isnull(serverPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, ''time'', 3), 10), 0) else 0 end) as serverPing3,
				avg(case when isnull(serverPingResults, '''') <> '''' then dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, ''time'', 4), 10), 0) else 0 end) as serverPing4
				from pingLog a
				where a.ymd >= @dStartDate
				group by case when isnull(a.friendlyName, '''') = '''' then a.serverName else a.friendlyName end
				having count(*) > 5
			) a
		where droppedPings > 0

	--***********************************************************************************************************
	-- Results
	--***********************************************************************************************************
	select identity(int) as ukey,
		servername, outageStart, outageStop,
		case when details is null
			then case when outageStop is null
				then ''Offline''
				else ''Not PINGing for '' + convert(varchar(20), convert(int, ceiling((convert(decimal(10,2), dateDiff(millisecond, outageStart, outageStop))/1000.00)/60.00))) + '' minute(s)''
				end
			else details
			end as details
		into #detailOutput
		from #results
		where not (
				dateDiff(day, outageStart, getDate()) > 5
				and outageStop is null
				and isnull(details, '''') <> ''Point Outage''
			)
		order by outageStart, serverName

	select identity(int) as ukey,
		serverName, connectionAttempts, connectionFailures, failureRate, availability, latestDrop,
		convert(varchar(20), dateDiff(hour, isnull(latestDrop, earliestData), latestData)) + '' hours'' as upTime
		into #summaryOutput
		from #summary
		order by serverName


	set @nThisUkey = 0

	while exists (select top 1 * from #detailOutput where ukey > @nThisUkey)
	begin
		set @cThisMessage = ''Outage details from '' + convert(varchar(20), @dStartDate, 120) + '' to present.'' + char(13) + char(13) +
				left(''Server Name'' + space(20), 20) + '' '' +
				left(''Begin'' + space(19), 19) + '' '' +
				left(''End'' + space(19), 19) + '' '' +
				left(''Details'' + space(35), 35) + char(13) +

				replicate(''='', 20) + '' '' +
				replicate(''='', 19) + '' '' +
				replicate(''='', 19) + '' '' +
				replicate(''='', 35) + char(13)

		select top 20
			@cThisMessage = @cThisMessage +
				left(serverName + space(20), 20) + '' '' +
				left(convert(varchar(19), outageStart, 120) + space(19), 19) + '' '' +
				left(isnull(convert(varchar(19), outageStop, 120), '''') + space(19), 19) + '' '' +
				left(details, 35) + char(13)
			from #detailOutput
			where ukey > @nThisUkey
			order by ukey

		set @cThisSubject = ''SAA : Outage detail report ('' + convert(varchar(20), @nThisUkey + 1) + '' - '' + convert(varchar(20), @nThisUkey + 20) + '')''

		set @nThisUkey = @nThisUkey + 20

		print @cThisSubject
		print @cThisMessage

		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
--		exec pr_sendMessage '''', ''user@example.org'', @cThisSubject, @cThisMessage
--		exec pr_sendMessage '''', ''user@example.org'', @cThisSubject, @cThisMessage
--		exec pr_sendMessage '''', ''user@example.org'', @cThisSubject, @cThisMessage
	end

	set @nThisUkey = 0

	while exists (select top 1 * from #summaryOutput where ukey > @nThisUkey)
	begin
		set @cThisMessage = ''Outage summary for servers that have failed from '' + convert(varchar(20), @dStartDate, 120) + '' to present.'' + char(13) + char(13) +
				left(''Server Name'' + space(20), 20) + '' '' +
				left(''Attempts'' + space(8), 8) + '' '' +
				left(''Failures'' + space(8), 8) + '' '' +
				left(''Fail Rate'' + space(9), 9) + '' '' +
				left(''Avail'' + space(7), 7) + '' '' +
				left(''Last Drop'' + space(19), 19) + '' '' +
				left(''Uptime'' + space(10), 10) + char(13) +

				replicate(''='', 20) + '' '' +
				replicate(''='', 8) + '' '' +
				replicate(''='', 8) + '' '' +
				replicate(''='', 9) + '' '' +
				replicate(''='', 7) + '' '' +
				replicate(''='', 19) + '' '' +
				replicate(''='', 10) + char(13)

		select top 20
			@cThisMessage = @cThisMessage +
				left(serverName + space(20), 20) + '' '' +
				right(space(8) + convert(varchar(8), connectionAttempts), 8) + '' '' +
				right(space(8) + convert(varchar(8), connectionFailures), 8) + '' '' +
				right(space(8) + convert(varchar(8), failureRate), 8) + ''% '' +
				right(space(6) + convert(varchar(6), availability), 6) + ''% '' +
				left(isnull(convert(varchar(19), latestDrop, 120), ''CURRENTLY DOWN'') + space(19), 19) + '' '' +
				left(uptime, 10) + char(13)
			from #summaryOutput
			where ukey > @nThisUkey
			order by ukey

		set @cThisSubject = ''SAA : Outage summary report ('' + convert(varchar(20), @nThisUkey + 1) + '' - '' + convert(varchar(20), @nThisUkey + 20) + '')''

		set @nThisUkey = @nThisUkey + 20

		print @cThisSubject
		print @cThisMessage

		exec pr_sendMessage '''', ''DBA'', @cThisSubject, @cThisMessage
--		exec pr_sendMessage '''', ''user@example.org'', @cThisSubject, @cThisMessage
--		exec pr_sendMessage '''', ''user@example.org'', @cThisSubject, @cThisMessage
--		exec pr_sendMessage '''', ''user@example.org'', @cThisSubject, @cThisMessage
	end


	drop table #websiteOutages
	drop table #results
	drop table #outages
	drop table #summary
	drop table #summaryOutput
	drop table #detailOutput

end
'
END
GO
