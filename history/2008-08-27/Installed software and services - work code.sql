use [installedSoftware]
go

select ukey_server, ukey_run, count(*) as numItems
	into #installHistory
	from runs a
	join runs_data b on a.ukey = b.ukey_run
	where a.ymd >= dateAdd(week, -1, getDate())
	group by ukey_server, ukey_run

delete #installHistory
	from #installHistory a
	join (
		select ukey_server, numItems
			from #installHistory
			group by ukey_server, numItems
			having count(*) = 1
		) b on a.ukey_server = b.ukey_server
			and a.numItems = b.numItems


select serverName,
	c.programName, c.installDate, c.version
	into #installedSoftware
	from notification..dm_servers a
	left outer join (
		select ukey_server, max(ukey_run) as ukey_run
			from #installHistory
			group by ukey_server
		) b on a.ukey = b.ukey_server
	left outer join runs_data c on a.ukey = c.ukey_server
		and b.ukey_run = c.ukey_run
		and (
			c.programName like '%landesk%'
			or c.programName like '%trend%'
			or c.programName like '%veritas%'
			or c.programName like '%arcserve%'
		)
	order by a.serverName


select ukey_server, max(ukey_run) as ukey_run
	into #counterHistory
	from configuration..runs a (nolock)
	join configuration..runs_data b (nolock) on a.ukey = b.ukey_run
	join configuration..dm_counters c (nolock) on b.ukey_counter = c.ukey
		and c.counterName = 'win32_service'
	where a.ymd >= dateAdd(day, -2, getDate())
	group by ukey_server

select
	e.serverName,
	max(case when keyName in ('displayname', 'caption') then keyvalue else '' end) as serviceName,
	max(case when keyName = 'state' then keyValue else '' end) as serviceState,
	max(case when keyName = 'description' then keyValue else '' end) as serviceDescription
	into #serviceState
	from #counterHistory a
	join configuration..runs_data b on a.ukey_run = b.ukey_run
		and a.ukey_server = b.ukey_server
	join configuration..dm_counters c on b.ukey_counter = c.ukey
		and counterName = 'win32_service'
	join configuration..dm_keyNames d on b.ukey_keyName = d.ukey
		and keyName in ('state', 'displayname', 'caption', 'description')
	join notification..dm_servers e on b.ukey_server = e.ukey
	group by e.serverName, b.instance

select
	a.*,
	b.[CA BrightStor Discovery Service],
	b.[CA BrightStor Universal Agent],
	b.[CA License Client],
	b.[CA License Server],
	b.[LANDesk (R) SDMCache Cleanup Service],
	b.[LANDesk Remote Control Service],
	b.[LANDesk Targeted Multicast],
	b.[LANDesk(R) Management Agent],
	b.[LANDesk(R) Software Monitoring Service],
	b.[NetBackup Client Service],
	b.[NetBackup SAN Client Fibre Transport Service],
	b.[OfficeScan NT Firewall],
	b.[OfficeScan NT Listener],
	b.[OfficeScan NT Proxy Service],
	b.[OfficeScanNT Listener],
	b.[OfficeScanNT Personal Firewall],
	b.[OfficeScanNT RealTime Scan],
	b.[Symantec AntiVirus Scan Engine]

	from (
		select serverName,
			max(case when programName like '%arcserve%client%' then programName else '' end) as [ArcServe Client],
			max(case when programName like '%arcserve%client%' then installDate else '' end) as [ArcServe Client Install Date],
			max(case when programName like '%arcserve%client%' then version else '' end) as [ArcServe Client Version],

			max(case when programName like '%arcserve%diagnostic%' then programName else '' end) as [ArcServe Diagnostic],
			max(case when programName like '%arcserve%diagnostic%' then installDate else '' end) as [ArcServe Diagnostic Install Date],
			max(case when programName like '%arcserve%diagnostic%' then version else '' end) as [ArcServe Diagnostic Version],

			max(case when programName like '%landesk%advance%' then programName else '' end) as [Landesk Advance],
			max(case when programName like '%landesk%advance%' then installDate else '' end) as [Landesk Advance Install Date],
			max(case when programName like '%landesk%advance%' then version else '' end) as [Landesk Advance Version],

			max(case when programName like '%landesk%base%' then programName else '' end) as [Landesk Base],
			max(case when programName like '%landesk%base%' then installDate else '' end) as [Landesk Base Install Date],
			max(case when programName like '%landesk%base%' then version else '' end) as [Landesk Base Version],

			max(case when programName like '%trend%client%' then programName else '' end) as [Trend Micro],
			max(case when programName like '%trend%client%' then installDate else '' end) as [Trend Micro Install Date],
			max(case when programName like '%trend%client%' then version else '' end) as [Trend Micro Version],

			max(case when programName like '%veritas%client%' then programName else '' end) as [Veritas],
			max(case when programName like '%veritas%client%' then installDate else '' end) as [Veritas Install Date],
			max(case when programName like '%veritas%client%' then version else '' end) as [Veritas Version]

			from #installedSoftware

			group by serverName
		) a
	left outer join (
		select serverName,
			max(case when serviceName = 'CA BrightStor Discovery Service' then serviceState else '' end) as [CA BrightStor Discovery Service],
			max(case when serviceName = 'CA BrightStor Universal Agent' then serviceState else '' end) as [CA BrightStor Universal Agent],
			max(case when serviceName = 'CA License Client' then serviceState else '' end) as [CA License Client],
			max(case when serviceName = 'CA License Server' then serviceState else '' end) as [CA License Server],
			max(case when serviceName = 'LANDesk (R) SDMCache Cleanup Service' then serviceState else '' end) as [LANDesk (R) SDMCache Cleanup Service],
			max(case when serviceName = 'LANDesk Remote Control Service' then serviceState else '' end) as [LANDesk Remote Control Service],
			max(case when serviceName = 'LANDesk Targeted Multicast' then serviceState else '' end) as [LANDesk Targeted Multicast],
			max(case when serviceName = 'LANDesk(R) Management Agent' then serviceState else '' end) as [LANDesk(R) Management Agent],
			max(case when serviceName = 'LANDesk(R) Software Monitoring Service' then serviceState else '' end) as [LANDesk(R) Software Monitoring Service],
			max(case when serviceName = 'NetBackup Client Service' then serviceState else '' end) as [NetBackup Client Service],
			max(case when serviceName = 'NetBackup SAN Client Fibre Transport Service' then serviceState else '' end) as [NetBackup SAN Client Fibre Transport Service],
			max(case when serviceName = 'OfficeScan NT Firewall' then serviceState else '' end) as [OfficeScan NT Firewall],
			max(case when serviceName = 'OfficeScan NT Listener' then serviceState else '' end) as [OfficeScan NT Listener],
			max(case when serviceName = 'OfficeScan NT Proxy Service' then serviceState else '' end) as [OfficeScan NT Proxy Service],
			max(case when serviceName = 'OfficeScanNT Listener' then serviceState else '' end) as [OfficeScanNT Listener],
			max(case when serviceName = 'OfficeScanNT Personal Firewall' then serviceState else '' end) as [OfficeScanNT Personal Firewall],
			max(case when serviceName = 'OfficeScanNT RealTime Scan' then serviceState else '' end) as [OfficeScanNT RealTime Scan],
			max(case when serviceName = 'Symantec AntiVirus Scan Engine' then serviceState else '' end) as [Symantec AntiVirus Scan Engine]
			from #serviceState
			where serviceName like '%arcserve%'
				or serviceName like '%landesk%'
				or servicename like '%trend%'
				or servicename like '%veritas%'
				or servicename like '%netbackup%'
				or serviceName in ('CA BrightStor Discovery Service', 'CA BrightStor Universal Agent', 'CA License Client', 'CA License Server',
					'OfficeScan NT Firewall', 'OfficeScan NT Listener', 'OfficeScan NT Proxy Service', 'OfficeScanNT Listener', 'OfficeScanNT Personal Firewall',
					'OfficeScanNT RealTime Scan', 'Symantec AntiVirus Scan Engine')
			group by serverName
		) b on a.serverName = b.serverName
	order by a.serverName

go

--drop table #counterHistory
--drop table #installedSoftware
--drop table #installHistory
--drop table #serviceState
