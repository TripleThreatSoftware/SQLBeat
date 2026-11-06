/****** Object:  StoredProcedure [dbo].[pr_checkStatus]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_checkStatus]
as
begin
	declare @cMessage varchar(8000)
	declare @cSubject varchar(2000)
	declare @nCount int
	declare @dDate dateTime

	set @cMessage = '<b>SQLBeat Status:</b><br>'

	set @nCount = (select count(*) from dm_servers (nolock) where isEnabled = 1)
	set @cMessage = @cMessage + '<b>Enabled servers:</b> ' + convert(varchar(20), @nCount) + '<br>'
	set @cSubject = 'Status report (' + convert(varchar(20), isnull(@nCount, 0)) + ' servers)'

	set @nCount = (select count(*) from dm_servers (nolock) where isEnabled = 1 and detailedCheck = 1)
	set @cMessage = @cMessage + '<b>Detailed check servers:</b> ' + convert(varchar(20), isnull(@nCount, 0)) + '<br>'

	set @dDate = (select max(lastDetailedCheck) from dm_servers (nolock) where isEnabled = 1 and detailedCheck = 1)
	set @cMessage = @cMessage + '<b>Last detailed check:</b> ' + convert(varchar(20), isnull(@dDate, ''), 120) + '<br>'

	set @nCount = (select count(distinct serverName) from processLog (nolock) where ymd >= dateAdd(hour, -2, getDate()) and serverName <> @@servername)
	set @cMessage = @cMessage + '<b>ProcessLog Servers:</b> ' + convert(varchar(20), isnull(@nCount, 0)) + '<br>'

	insert into notificationLog_stage (subject, message, serverName, severity) values (@cSubject, @cMessage, @@servername, 2)
end
GO
