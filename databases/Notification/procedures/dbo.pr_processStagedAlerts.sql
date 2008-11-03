--select top 100 * from notificationLog
--select top 100 * from notificationLog_stage


CREATE procedure [pr_processStagedAlerts]
as
begin
	declare @nMaxUkey int
	declare @nMinUkey int
	declare @nUkey int
	declare @nSeverity int
	declare @nOffHoursPriority int

	declare @cQueuedMessages varchar(8000)
	declare @cThisServerName varchar(100) -- this is to accomodate the Event Log code
	declare @cDevelopersContacted varchar(200)
	declare @cLastServerName varchar(100)
	declare @cEmailDestination varchar(200)
	declare @cFriendlyName varchar(100)
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(2000)
	declare @cOffHoursSubject varchar(2000)

	declare @dMessageDate dateTime

	declare @lDevelopersContacted bit
	declare @bIsJobFailure bit
	declare @bIsLogShippingJobFailure bit
	declare @bIsLongRunningJob bit
	declare @bIsBlocking bit
	declare @bIsLongRunningProcess bit
	declare @bIsDriveSpace bit
	declare @bIsLogSize bit
	declare @bIsEventLog bit
	declare @bIsException bit
	declare @bTesting bit
	declare @bIsService bit
	declare @bIsConnectivity bit
	declare @bIsInstalledSoftware bit

	set @bTesting = 0

	create table #exceptions (messageSubstring varchar(100), emailDestination varchar(200))

	insert into #exceptions (messageSubstring, emailDestination)
	select 'admin', 'DBA'
	union
	select 'number of connections', 'DBA'
	union
	select 'number of waiting connections', 'DBA'
	union
	select 'WMI', 'DBA'
	union
	select 'Error Invalid parameter', 'DBA'
	union
	select 'sleep', 'DBA'
	union
	select @@servername, 'DBA'

	-- we need to establish a range to look at in case new messages are added as we're processing
	select @nMinUkey = min(ukey), @nMaxUkey = max(ukey) from notificationLog_stage

	if @nMinUkey is null and @nMaxUkey is null
		return

	-- We need to know if it's business hours so we can queue the low priority alerts
	declare @bIsOffHours bit

	if dbo.fn_isBusinessHours() = 1
		set @bIsOffHours = 0
	else
		set @bIsOffHours = 1

	--***************************************************************************************************
	-- Get rid of duplicate messages
	--***************************************************************************************************

	-- get rid of doubles in the staged messages
	delete a
		from notificationLog_stage a
		join (
			select serverName, subject, min(ukey) as ukey
				from notificationLog_stage
				group by serverName, subject
				having count(*) > 1
			) b on a.serverName = b.serverName
				and a.subject = b.subject
				and a.ukey <> b.ukey

	-- don't re-send messages that have gone out in the last little while
	delete notificationLog_stage
		from notificationLog_stage a
		join notificationLog b on a.serverName = b.serverName
			and a.subject = b.subject
--			and a.message = b.message
			and b.ymd >= dateAdd(hour, -48, getDate())
		where a.ukey >= @nMinUkey
			and a.ukey <= @nMaxUkey

	-- deprioritize high impact messages from low impact servers off hours
	if @bIsOffHours = 1
		update notificationLog_stage
			set severity = case
--				when severity = 1 and b.offHoursPriority <> 1 then 2
				when severity = 1 and c.isProduction <> 1 then 2
				else severity end
			from notificationLog_stage a
			join dm_servers b on a.serverName = b.serverName
			join dm_serverGroups c on b.ukey_group = c.ukey
--			where isnull(a.isEventLog, 0) = 0

	update notificationLog_stage
		set severity = 2
		from notificationLog_stage a
		where (
				isLongRunningJob = 1
				or isJobFailure = 1
			)
			and (
				subject like '%monitor sql statistics%'
				or subject like '%configuration check%'
				or subject like '%import weblogs%'
				or subject like '%maintenance%'
				or subject like '%monitor%'
				or subject like '%report%'
				or subject like '%fragmentation check%'
				or subject like '%integrity check%'
				or subject like '%service check%'
				)

	insert into notificationLog (ymd, subject, message, messageSent, messageSentDate, severity,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog, serverName, isService, isConnectivity, isInstalledSoftware)
	select a.ymd, subject, message, 1 as messageSent, null as messageSentDate, severity, isJobFailure,
		isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog, a.serverName, isService, isConnectivity, isInstalledSoftware
		from notificationLog_stage a
		join dm_servers b on a.serverName = b.serverName
		where b.silenceUntil is not null
			and getDate() < b.silenceUntil

	delete notificationLog_stage
		from notificationLog_stage a
		join dm_servers b on a.serverName = b.serverName
		where b.silenceUntil is not null
			and getDate() < b.silenceUntil

	--***************************************************************************************************
	-- Manual cleanup
	--***************************************************************************************************

	delete from notificationLog_stage where isJobFailure = 1 and subject like '%import weblogs%'

	-- any time the purge is blocking, ignore it
	delete
		from notificationLog_stage
		where isBlocking = 1
			and serverName = 'mssql-ny'
			and (message like '%purgebydays%' or message like '%msrepl%')
			and datePart(hour, ymd) between 13 and 15

	-- any time replication is running long, ignore it
	delete
		from notificationLog_stage
		where isLongRunningProcess = 1
			and serverName = 'mssql-ny'
			and (
					(message like '%sp_MSadd%' and message like '%clusterservice%')
					or (message like '%clusterservice%' and message like '%distribution%')
				)

	-- any time replication is kicking sand during the purge, ignore it
	delete
		from notificationLog_stage
		where isLongRunningProcess = 1
			and serverName = 'mssql-ny'
			and (message like '%sp_replcmds%' or message like '%sp_msget_repl_commands%')
			and datePart(hour, ymd) between 13 and 15

	-- when the purge kicks off, ignore replication synch messages
	delete
		from notificationLog_stage
		where subject like '%subscription%'
			and subject like '%out of synch%'
			and subject like '%0 hrs%'
			and datePart(hour, ymd) between 13 and 15

	delete from notificationLog_stage
		where message like '%system failed to register host%'
			or message like '%Replication of license information%'
			or message like '%Group Policy objects%'
			or message like '%Security policies are propagated with warning%'
			or message like '%Group Policy processing%'

	-- any time we've got a box down for a long time, it'll start to show up in the 15 minute summary
	-- to cut down on the number of email messages that go out
	insert into notificationLog (ymd, subject, message, messageSent, messageSentDate, severity,
		isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog, serverName, isService, isConnectivity)
	select a.ymd, subject, message, 1 as messageSent, getDate() as messageSentDate, severity, isJobFailure,
		isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
		isDriveSpace, isLogSize, isEventLog, a.serverName, isService, isConnectivity
		from notificationLog_stage a
		join (
			select serverName, max(ymd) as ymd
				from pingLog (nolock)
				where isServerPingable = 1
				group by serverName
				having dateDiff(minute, max(ymd), getDate()) >= 15
			) b on a.serverName = b.serverName
		where isConnectivity = 1

	delete notificationLog_stage
		from notificationLog_stage a
		join (
			select serverName, max(ymd) as ymd
				from pingLog (nolock)
				where isServerPingable = 1
				group by serverName
				having dateDiff(minute, max(ymd), getDate()) >= 15
			) b on a.serverName = b.serve
rName
		where isConnectivity = 1

	--***************************************************************************************************
	-- Get down to the business of sending
	--***************************************************************************************************
	set @cQueuedMessages = ''
	set @nUkey = 0
	set @bIsException = 0

	if @bTesting = 0
	begin
		insert into notificationLog (ymd, subject, message, messageSent, messageSentDate, severity,
			isJobFailure, isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
			isDriveSpace, isLogSize, isEventLog, serverName, isService, isConnectivity, isInstalledSoftware)
		select ymd, subject, message, 1 as messageSent, getDate() as messageSentDate, severity, isJobFailure,
			isLogShippingJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess,
			isDriveSpace, isLogSize, isEventLog, serverName, isService, isConnectivity, isInstalledSoftware
			from notificationLog_stage
			where ukey >= @nMinUkey
				and ukey <= @nMaxUkey

		delete from notificationLog_stage
			where ukey >= @nMinUkey
				and ukey <= @nMaxUkey
	end

	drop table #exceptions
end


GO
