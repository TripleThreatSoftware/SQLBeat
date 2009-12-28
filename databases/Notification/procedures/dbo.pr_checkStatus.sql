alter procedure pr_checkStatus
as
begin
	declare @cMessage varchar(8000)
	declare @cSubject varchar(2000)
	declare @nCount int
	declare @dDate dateTime

	set @cMessage = '<b>SQLBeat Status:</b><br>'

	set @nCount = (select count(*) from dm_servers (nolock) where isEnabled = 1)
	set @cMessage = @cMessage + '<b>Enabled servers:</b> ' + convert(varchar(20), @nCount) + '<br>'
	set @cSubject = 'Status report (' + convert(varchar(20), @nCount) + ' servers)'

	set @nCount = (select count(*) from dm_servers (nolock) where isEnabled = 1 and detailedCheck = 1)
	set @cMessage = @cMessage + '<b>Detailed check servers:</b> ' + convert(varchar(20), @nCount) + '<br>'

	set @dDate = (select max(lastDetailedCheck) from dm_servers (nolock) where isEnabled = 1 and detailedCheck = 1)
	set @cMessage = @cMessage + '<b>Last detailed check:</b> ' + convert(varchar(20), @dDate, 120) + '<br>'

	set @nCount = (select count(distinct serverName) from processLog (nolock) where ymd >= dateAdd(hour, -2, getDate()) and serverName <> @@servername)
	set @cMessage = @cMessage + '<b>ProcessLog Servers:</b> ' + convert(varchar(20), @nCount) + '<br>'

	exec pr_sendMessage '', 'DBA', @cSubject, @cMessage, 1
end
