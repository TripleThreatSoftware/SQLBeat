/****** Object:  StoredProcedure [dbo].[pr_syslog_readevents]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--CREATE TABLE [dbo].[syslog](
--	ukey bigint identity,
--	ymd dateTime default getDate(),
--	ukey_server int,

--	priority varchar(500), hostname varchar(500), messageText varchar(8000)
--)

--create clustered index ix_syslog_ukey on syslog (ukey) with fillfactor = 70
--go
--create index ix_syslog_hostname_inc_ukey on syslog (hostname) include (ukey) with fillfactor = 70
--go
-- --drop index syslog.ix_syslog_hostname_devicetime_tag_messageText_inc_ukey
--create index ix_syslog_hostname_devicetime_tag_messageText_inc_ukey on syslog (hostname, ymd, priority, messageText) include (ukey) with fillfactor = 80
--go

-- select top 100 * from notificationLog where subject like '%office%' order by ymd desc

-- exec sp_rename 'syslog', 'syslog_old'
-- drop table #syslog

CREATE procedure [dbo].[pr_syslog_readevents]  @cFilePath varchar(8000)
as
begin

	declare @cSQLString nvarchar(4000)
	declare @cSubject varchar(8000)
	declare @cMessage varchar(max)
	declare @cFileName varchar(500)
	declare @cHostname varchar(500)
	declare @nRowCount int
	declare @dTimestamp dateTime

	if exists (select top 1 id from sysobjects where name = 'tmp_syslogdata')
		drop table tmp_syslogdata

	create table tmp_syslogdata (ymd dateTime, priority varchar(500), hostname varchar(500), messageText varchar(8000))
	create table #syslog (ymd dateTime, priority varchar(500), hostname varchar(500), messageText varchar(8000), environment varchar(500), severity int)
	create table #results (wideString varchar(8000))

	create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)
	create clustered index ix_tmp_filesToImport on #filesToImport (ukey) with fillfactor = 80

	exec sandbox.dbo.pr_recurseDirectories @cFilePath
--	select * from #filesToImport
	set @cFileName = ''

	while exists (select top 1 filePath from #filesToImport where fileDate >= dateadd(day, -2, getDate()) and filePath > @cFileName)
	begin

		select top 1
			@cFileName = filePath
			from #filesToImport
			where fileDate >= dateadd(day, -2, getDate())
				and filePath > @cFileName
			order by filePath

		truncate table tmp_syslogdata

		set @cSQLString = 'bcp ' + db_name() + '.dbo.tmp_syslogdata in ' + @cFileName + ' -c -T -F2 -t"\t"'

		insert into #results
		exec master..xp_cmdshell @cSQLString

		insert into #syslog (ymd, priority, hostname, messageText, environment)
		select ymd, priority, hostname, messageText,
			case
				when charindex('_office_', @cFileName) > 0 then 'OFFICE'
				when charindex('_ATL_', @cFileName) > 0 then 'ATL'
				when charindex('_SEA_', @cFileName) > 0 then 'SEA'
				when charindex('_AMS_', @cFileName) > 0 then 'AMS'
				when charindex('_LHR_', @cFileName) > 0 then 'LHR'
				when charindex('_PDX_', @cFileName) > 0 then 'PDX'
				else 'Other'
				end
			 from tmp_syslogdata

	end

	insert into syslog (ymd, priority, hostname, messageText, environment)
	select a.ymd, a.priority, a.hostname, a.messageText, a.environment
		from #syslog a
		left outer join syslog b on isnull(a.hostname, '') = isnull(b.hostname, '')
			and isnull(a.ymd, '') = isnull(b.ymd, '')
			and isnull(a.priority, '') = isnull(b.priority, '')
			and isnull( a.messageText, '') = isnull(b.messageText, '')

		where b.ukey is null
			and a.ymd >= dateadd(hour, -12, getDate())

	insert into dm_servers (servername, ukey_group, isEnabled)
	select a.hostname, 10, 0
		from (select distinct hostname from #syslog) a
		left outer join dm_servers b on a.hostname = b.servername
		where b.ukey is null

	update syslog
		set ukey_server = b.ukey
		from syslog a
		join dm_servers b on a.hostname = b.servername
		where a.ukey_Server is null

	update #syslog
		set severity = 1
		where messageText like '%gateway alarm%'
			and isnumeric(replace(replace(substring(messageText, charindex('Loss:', messageText), 100), 'Loss:', ''), '%)', '')) = 1
			and (
				(charindex('seapf01', messageText) > 0 and convert(int, replace(replace(substring(messageText, charindex('Loss:', messageText), 100), 'Loss:', ''), '%)', '')) > 25)
				or (charindex('gw_inap_64', messageText) > 0 and convert(int, replace(replace(substring(messageText, charindex('Loss:', messageText), 100), 'Loss:', ''), '%)', '')) > 25)
				or (charindex('_of1_', messageText) > 0 and convert(int, replace(replace(substring(messageText, charindex('Loss:', messageText), 100), 'Loss:', ''), '%)', '')) > 25)
				or (
					not charindex('seapf01', messageText) > 0
					and not charindex('gw_inap_64', messageText) > 0
					and not charindex('_of1_', messageText) > 0
					and convert(int, replace(replace(substring(messageText, charindex('Loss:', messageText), 100), 'Loss:', ''), '%)', '')) > 10
					)
				)

	update #syslog
		set severity = 1
		where messageText like '%link up%'
			or messageText like '%link down%'

	update #syslog
		set severity = 3
		where charindex('[SNORT]', messageText) > 0
			or  charindex(' SNORT[', messageText) > 0
			or messageText like '%sshguard%now monitoring%'
			or messageText like '%sshguard%exiting on signal%'
			or messageText like '%failed to resolve host pfb_spmon42_whitelist_v4%'


	-- select top 100 *, replace(replace(substring(messageText, charindex('Loss:', messageText), 100), 'Loss:', ''), '%)', '') from syslog (nolock) where messageText like '%gateway alarm%' and ymd >= '2021-09-28' order by ymd desc

	-- ****************************************************************************************************************************************************************************************
	-- ****************************************************************************************************************************************************************************************
	-- Rate limit the "rate limit exceeded" messages

--declare @cSubject varchar(8000)
--declare @cMessage varchar(max)
--declare @cFileName varchar(500)
--declare @cHostname varchar(500)
--declare @nRowCount int
--declare @dTimestamp dateTime

-- drop table #syslog
--select *
--	into #syslog
--	from syslog
--	where ymd >= dateadd(hour, -12, getDate())


--select * from #syslog where messageText like '%incoming DHCP messages on this interface exceeded the rate%'

	if (select count(*) from #syslog where messageText like '%incoming DHCP messages on this interface exceeded the rate%' and ymd >= dateadd(hour, -12, getDate())) > 20
	begin
		set @cSubject = ''
		set @cMessage = ''
		set @cHostname = ''

		if object_id('tempdb..#messages') is not null
			drop table #messages

		select * into #messages from #syslog where messageText like '%incoming DHCP messages on this interface exceeded the rate%' and ymd >= dateadd(hour, -12, getDate())

		while exists (select top 1 hostname from #messages where hostname > @cHostname)
		begin
			select top 1
				@cHostname = hostname,
				@cMessage = 'Example alert: ' + max(messageText),
				@cSubject = max(left('[' + environment + ' ' + rtrim(ltrim(priority)) + '] ' + messageText, 300)),
				@dTimestamp = max(ymd)
				from #messages
				where hostname > @cHostname
				group by hostname
				order by hostname

			print @cHostname

			set @nRowCount = (select count(*) from #messages where hostname = @cHostname)

			set @cSubject = 'Repeating alert (' + convert(varchar(20), @nRowcount) + 'x): ' + @cSubject

			--select @dTimestamp, @cSubject, @cMessage, 1, @cHostName
			if @cSubject like '%dhcp%exceeded the rate%'
				insert into notificationLog_Stage (ymd, subject, message, severity, serverName) values (@dTimestamp, @cSubject, @cMessage, 2, @cHostName)
			else
				insert into notificationLog_Stage (ymd, subject, message, severity, serverName) values (@dTimestamp, @cSubject, @cMessage, 1, @cHostName)
		end

		delete from #syslog where messageText like '%incoming DHCP messages on this interface exceeded the rate%'
	end

	-- ****************************************************************************************************************************************************************************************
	-- ****************************************************************************************************************************************************************************************
	-- roll up duplicate dpinger messages

	-- declare @cSubject varchar(500), @cMessage varchar(8000), @cHostname varchar(500), @nRowcount int, @dTimestamp dateTime

	if object_id('tempdb..#messages_dpinger') is not null
		drop table #messages_dpinger

	select top 0 messageText
		into #messages_dpinger
		from #syslog

	if object_id('tempdb..#dpinger') is not null
		drop table #dpinger

	select hostname, ymd, count(*) as numAlerts, identity(int) as ukey into #dpinger from #syslog where messageText like '%dpinger%latency_alarm%' and ymd >= dateadd(hour, -12, getDate()) group by hostname, ymd having count(*) >= 5

	if @@rowcount > 0
	begin

		set @cSubject = ''
		set @cMessage = ''
		set @cHostname = ''

		declare @dYMD dateTime = ''
		declare @nUkey int = 0

		while exists (select top 1 ukey from #dpinger where ukey > @nUkey)
		begin
			select top 1
				@dYMD = ymd,
				@cHostName = hostname,
				@nUkey = ukey
				from #dpinger
				where ukey > @nUkey
				order by ukey

			-- print @cHostname

			insert into #messages_dpinger
			select messageText
				from #syslog
				where messageText like '%dpinger%latency_alarm%'
					and ymd >= dateadd(hour, -12, getDate())
					and hostname = @cHostName
					and ymd = @dYMD
					and messageText is not null

			set @nRowCount = (select count(*) from #messages_dpinger)

			set @cSubject = 'DPINGER Latency Alert (' + convert(varchar(20), @nRowcount) + 'x) @ ' + convert(varchar(20), @dYMD, 120)
			set @cMessage = ''

			select @cMessage = @cMessage + messageText + '<br>'
				from #messages_dpinger

			--select @dYMD, @cSubject, @cMessage, 1, @cHostName
			insert into notificationLog_Stage (ymd, subject, message, severity, serverName) values (@dYMD, @cSubject, convert(varchar(8000), @cMessage), 1, @cHostName)
		end

		delete from #syslog where messageText like '%dpinger%latency_alarm%'
	end

	-- ****************************************************************************************************************************************************************************************
	-- ****************************************************************************************************************************************************************************************
	-- roll up port flops

	-- alter table #syslog add severity int
	-- declare @cSubject varchar(500), @cMessage varchar(8000), @cHostname varchar(500), @nRowcount int, @dTimestamp dateTime

	if object_id('tempdb..#portflop') is not null
		drop table #portflop

	-- select * from #portflop
	select
		hostname,
		ymd
		into #portflop
		from #syslog
		where (messageText like '%TRAPMGR: Link Up%' or messageText like '%TRAPMGR: Link Down%')
			and ymd >= dateadd(hour, -12, getDate())

	update #syslog
		set severity = 1
		where (messageText like '%TRAPMGR: Link Up%' or messageText like '%TRAPMGR: Link Down%')

	-- if we have the link up/down, deprioritize the role change alert
	update #syslog
		set severity = 3
		from #syslog a
		join #portflop b on a.hostname = b.hostname
			and a.ymd = b.ymd
			and a.messageText like '%Port % role changing from%'

	-- we know this to be a bad IPMI port on the Hypervisor.
	update #syslog
		set severity = 3
		from #syslog a
		where (messageText like '%TRAPMGR: Link Up%' or messageText like '%TRAPMGR: Link Down%')
			and messageText like '%0/47%'
			and ymd <= '2023-08-01' -- artificial ending date

	-- ****************************************************************************************************************************************************************************************
	-- ****************************************************************************************************************************************************************************************


	insert into notificationLog_Stage (ymd, subject, message, severity, serverName)
	select ymd,
		left('[' + environment + ' ' + rtrim(ltrim(priority)) + '] ' + case
			when messageText like '%rc.filter_synchronize:%' then substring(messageText, charindex('rc.filter_synchronize:', messageText), 500)
			else messageText
			end, 300) as subject,
		case
			when messageText like '%rc.filter_synchronize:%' then substring(messageText, charindex('rc.filter_synchronize:', messageText), 500)
			else messageText
			end,
		isnull(severity, 2),
		hostname
		-- select *
		from #syslog (nolock)
		where 3=3
			and not messageText like '%snort%priority: 2%'
			and not messageText like '%snort%priority: 3%'
			and not messageText like '%snort%pruned%'
			and not messageText like '%filterlog%'
			and not messageText like '%dhcplease%'
			and not messageText like '%update_urltables%does not need updating%'
			and not messageText like '%dnsmasq%'
			and not messageText like '%vici client%'
			and not messageText like '%charon%'

			and not messageText like '%check_reload_status%Syncing firewall%'
			and not messageText like '%check_reload_status%reloading filter%'
			and not messageText like '%check_reload_status%restarting openvpn%'
			and not messageText like '%check_reload_status%restarting ipsec%'
			and not messageText like '%check_reload_status%updating dyndns%'

			and not messageText like '%pfblockerng%dnsbl%webserver started%'
			and not messageText like '%pfblockerng%dnsbl%webserver stopped%'
			and not (priority = 'User.Notice' and right(messageText, 1) = ':')

			and not messageText like '%urltables%starting%'
			and not messageText like '%urltables%sleeping%'
			and not messageText like '%session timed out%'
			and not messageText like '%snort% attempt %'
			and not messageText like '%snort% attempted %'
			and not messageText like '%snort%up to date%'
			and not messageText like '%snort%downloaded successfully%'

			and not messageText like '%10.1.10.50%'
			and not messageText like '%xmlrpc sync%'
			and not messageText like '%snort has restarted with your new set of rules%'
			and not messageText like '%enabling flowbit-required%'
			and not messageText like '%rules update has finished%'
			and not messageText like '%xmlrpc reload%'
			and not messageText like '%check_reload_status: Reloading filter%'
			and not messageText like '%xmlrpc%versioncheck%'
			and not messageText like '%check_reload_status: Syncing firewall%'
			and not messageText like '%pfblockerng%starting cron process%'
			and not messageText like '%pfblockerng%skipping filter reload%'
			and not (priority in ('Daemon.Info') and messageText like '%charon%')
			and not (priority in ('Daemon.Notice') and messageText like '%openvpn%')
			and not (priority in ('Auth.Notice') and messageText like '%openvpn%')
			and not (priority in ('Local7.Debug', 'Local7.Info') and hostname = '10.1.10.1')
			and not (hostname = '10.10.10.253' and messageText like '%72.28.104.97%' and getDate() < '2020-08-10')
			and not (messageText like '%unbound%' and priority = 'Daemon.Info')
			and not messageText like '%unbound%init%module%'
			and not messageText like '%rpc downgrade%10.10.10.42%'
			and not messageText like '%mem exhaustion%10.10.10.31%'
			and not messageText like '%ETPRO EXPLOIT%outlook rce%10.10.10.43%'
			and ymd >= dateadd(hour, -12, getDate())

			and not right(messageText, 3) = ']: '
			and not messageText like '%vty_read: read error on vty client fd %, closing: Connection reset by peer%'
			and not messageText like '%buffer_flush failed on vty client fd %, closing%'
			and not messageText like '%dropbear%: Exit before auth: Exited normally%'
			and not messageText like '%Nothing has been configured to be synched%'
			and not messageText like '%sshd%10.10.10.42%'
			and not messageText like '%softflowd%' --added 20220723 to keep queue from clogging up by request of netsec
			and not messageText like '%filterdns%Adding Action: pf table:%' --added 20220801 - The SNORT_passlist_master alias has thousands of IPs so each time it rebuilds it spews out all of these informational events that are completely useless.

			and not messageText like '%successful login%'
			and not messageText like '%configuration reload%'
			and not messageText like '%sending inform timeout trace%'
			and not messageText like '%Interfaces settings changed%'
			and not messageText like '%Gateway, none ''available'' for inet6, use the first one configured%'
			and not messageText like '%One or more IPsec tunnel endpoints has changed its IP%'
			and not messageText like '%Configuration Change: zeus%'
			and not messageText like '%SNORTBlockCount%'

			and not messageText like '%removing statis route for%'
--			and not messageText like '%%'

		order by ymd desc

	--insert into notificationLog_Stage (ymd, subject, message, severity, serverName)
	--select ymd,
	--	left('[' + environment + '] SNORT blocking GoogleBot at ' + convert(varchar(20), ymd, 120), 300) as subject,
	--	messageText,
	--	2,
	--	hostname
	--	-- select *
	--	from #syslog
	--	where messageText like '%66.249.66%'
	--		and ymd >= dateadd(hour, -12, getDate())
	--	order by ymd desc

	--insert into notificationLog_Stage (ymd, subject, message, severity, serverName)
	--select ymd,
	--	left('[' + environment + '] SNORT blocking Azure-West-US at ' + convert(varchar(20), ymd, 120), 300) as subject,
	--	messageText,
	--	2,
	--	hostname
	--	-- select *
	--	from #syslog
	--	where messageText like '%40.91.82%'
	--		and ymd >= dateadd(hour, -12, getDate())
	--	order by ymd desc

	--insert into notificationLog_Stage (ymd, subject, message, severity, serverName)
	--select ymd,
	--	left('[' + environment + '] SNORT blocking Azure-Central-US at ' + convert(varchar(20), ymd, 120), 300) as subject,
	--	messageText,
	--	2,
	--	hostname
	--	-- select *
	--	from #syslog
	--	where (messageText like '%13.86.97%'  or messageText like '%13.86.98%')
	--		and ymd >= dateadd(hour, -12, getDate())
	--	order by ymd desc

	--insert into notificationLog_Stage (ymd, subject, message, severity, serverName)
	--select ymd,
	--	left('[' + environment + '] SNORT blocking Azure-NorthCentral-US at ' + convert(varchar(20), ymd, 120), 300) as subject,
	--	messageText,
	--	2,
	--	hostname
	--	-- select *
	--	from #syslog
	--	where (messageText like '%23.100.224%'  or messageText like '%23.100.225%')
	--		and ymd >= dateadd(hour, -12, getDate())
	--	order by ymd desc

	--insert into notificationLog_Stage (ymd, subject, message, severity, serverName)
	--select ymd,
	--	left('[' + environment + '] SNORT blocking Azure-SouthCentral-US at ' + convert(varchar(20), ymd, 120), 300) as subject,
	--	messageText,
	--	2,
	--	hostname
	--	-- select *
	--	from #syslog
	--	where (messageText like '%20.45.5.%')
	--		and ymd >= dateadd(hour, -12, getDate())
	--	order by ymd desc

	--insert into notificationLog_Stage (ymd, subject, message, severity, serverName)
	--select ymd,
	--	left('[' + environment + '] SNORT blocking Azure-East-US at ' + convert(varchar(20), ymd, 120), 300) as subject,
	--	messageText,
	--	2,
	--	hostname
	--	-- select *
	--	from #syslog
	--	where (messageText like '%20.42.35.%')
	--		and ymd >= dateadd(hour, -12, getDate())
	--	order by ymd desc


	drop table #filesToImport
	drop table #syslog
	drop table #results
end
-- select top 500 * from syslog where messageText like '%starting cron process%' order by ymd desc
GO
