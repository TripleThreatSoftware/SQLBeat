/****** Object:  StoredProcedure [dbo].[pr_monitorIPAddresses]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_monitorIPAddresses]
as
begin
	select
		servername,
		left(ipAddress, charindex(']', ipAddress) - 1) as ipAddress,
		min(ymd) as firstSeen,
		max(ymd) as lastSeen
		into #serverIP
		from (
			select
				serverName,
				substring(serverPingResults, charindex('[', serverPingResults) + 1, 100) as ipAddress,
				ymd
				from pingLog (nolock)
				where charindex('[', serverPingResults) <> 0
					and ymd >= dateAdd(hour, -2, getDate())
			) a
		group by serverName, left(ipAddress, charindex(']', ipAddress) - 1)

	select a.*, identity(int) as ukey
		into #changes
		from #serverIP a
		join (
			select serverName
				from #serverIP
				group by serverName
				having count(*) > 1
			) b on a.serverName = b.serverName
		order by a.serverName, a.firstSeen

	insert into notificationLog_stage (serverName, isConnectivity, subject, message, severity)
	select a.serverName, 1 as isConnectivity,
		'IP address changed from ' + a.ipAddress + ' to ' + b.ipAddress + ' around ' + convert(varchar(20), a.lastSeen, 120) + '.' as subject,
		'IP address ' + a.ipAddress + ' was last seen at ' + convert(varchar(20), a.lastSeen, 120) + '.' + char(13) +
			'IP Address ' + b.ipAddress + ' was first seen at ' + convert(varchar(20), b.firstSeen, 120) + '.' as message,
		1 as severity
		from #changes a
		join #changes b on a.ukey = b.ukey - 1
			and a.serverName = b.serverName

	drop table #serverIP
	drop table #changes
end
GO
