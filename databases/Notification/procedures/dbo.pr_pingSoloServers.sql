-- ================================================================================================
-- Notification.dbo.pr_pingSoloServers
--
-- Calls pr_pingServer for each configured device in a server group. Job: "PING check solo servers -
-- [GROUP]".
-- ================================================================================================
/****** Object:  StoredProcedure [dbo].[pr_pingSoloServers]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    procedure [dbo].[pr_pingSoloServers] (@nGroupToCheck int)
as
begin
	set nocount on

	declare @cServerName varchar(200)
	declare @cSQLString nvarchar(2000)
	declare @cSubject varchar(200)
	declare @cMessage varchar(200)
	declare @dLastCheck dateTime
	declare @dMinutesSinceLastCheck int
	declare @bSkipNextRun bit
	declare @nReturnStatus int

	set @cServerName = ''

	while exists (
		select top 1 *
			from dm_servers (nolock)
			where
				servername > @cServerName
				and isEnabled = 1
				and pingCheck = 1
				and (lastPingCheck is null or dateDiff(minute, lastPingCheck, getDate()) > isnull(pingCheckMinuteInterval, 5))
				and ukey_group = @nGroupToCheck
--				and detailedCheck = 0
		)
	begin

		select top 1
			@cServerName = serverName,
			@dLastCheck = isnull(lastPingCheck, dateAdd(hour, -24, getDate())),
			@bSkipNextRun = skipNextRun
			from dm_servers  (nolock)
			where
				servername > @cServerName
				and isEnabled = 1
				and pingCheck = 1
				and (lastPingCheck is null or dateDiff(minute, lastPingCheck, getDate()) > isnull(pingCheckMinuteInterval, 5))
				and ukey_group = @nGroupToCheck
--				and detailedCheck = 0

			order by serverName

		print @cServerName

		if isnull(@bSkipNextRun, 0) = 0
			exec @nReturnStatus = pr_pingServer @cServerName
		else
			update dm_servers with (rowlock)
				set skipNextRun = 0
				where serverName = @cServerName
					and isEnabled = 1

	end
end
GO
