CREATE    procedure [pr_pingSoloServers] (@nGroupToCheck int)
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
