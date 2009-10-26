SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER    procedure [dbo].[pr_examineAllServers] (@nServerGroup int)
as
begin
	set nocount on

	insert into notificationLog_history (stepName, ukey_group) values ('START All', @nServerGroup)

	declare @cServerName varchar(200)
	declare @cSQLString nvarchar(2000)
	declare @cSubject varchar(200)
	declare @cMessage varchar(200)
	declare @dLastCheck dateTime
	declare @dMinutesSinceLastCheck int
	declare @bSkipNextRun bit

	set @cServerName = ''

	while exists (
		select top 1 *
			from dm_servers
			where servername > @cServerName
				and isEnabled = 1
				and detailedCheck = 1
				and (lastDetailedCheck is null or dateDiff(minute, lastDetailedCheck, getDate()) > isnull(detailedCheckMinuteInterval, 5))
				and ukey_group = @nServerGroup
		)
	begin

		select top 1
			@cServerName = serverName,
			@dLastCheck = isnull(lastDetailedCheck, dateAdd(hour, -24, getDate())),
			@bSkipNextRun = skipNextRun
			from dm_servers
			where servername > @cServerName
				and isEnabled = 1
				and detailedCheck = 1
				and (lastDetailedCheck is null or dateDiff(minute, lastDetailedCheck, getDate()) > isnull(detailedCheckMinuteInterval, 5))
				and ukey_group = @nServerGroup

			order by serverName

		if isnull(@bSkipNextRun, 0) = 0
		begin
			set @dMinutesSinceLastCheck = dateDiff(minute, @dLastCheck, getDate()) + 30
			set @dLastCheck = getDate()

			-- This way, if one fails with a recoverable error the rest will continue
			-- Plus, we pass in the runtime of the last call so it'll know to look further back
			-- if it's running long
			set @cSQLString = 'exec pr_examineServer [' + @cServerName + '], ' + convert(varchar(20), @dMinutesSinceLastCheck)
			exec sp_executeSQL @cSQLString

			if @@error <> 0
			begin
				set @cSubject = 'Failed to make contact with ' + @cServerName
				set @cMessage = 'SQLBeat failed to make contact with ' + @cServerName

				insert into notificationLog_stage (subject, message, serverName, severity) values (
					@cSubject, @cMessage, @cServerName, 2)
			end

			update dm_servers
				set lastDetailedCheck = @dLastCheck
				where serverName = @cServerName
					and isEnabled = 1
					and detailedCheck = 1
		end
		else
			update dm_servers
				set skipNextRun = 0
				where serverName = @cServerName
					and isEnabled = 1
					and detailedCheck = 1

	end

	insert into notificationLog_history (stepName, ukey_group) values ('END All', @nServerGroup)

end
