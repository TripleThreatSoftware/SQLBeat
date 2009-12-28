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
	declare @nMinutesSinceLastCheck int
	declare @bSkipNextRun bit

	set @cServerName = ''

	while exists (
		select top 1 *
			from dm_servers (nolock)
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
			from dm_servers  (nolock)
			where servername > @cServerName
				and isEnabled = 1
				and detailedCheck = 1
				and (lastDetailedCheck is null or dateDiff(minute, lastDetailedCheck, getDate()) > isnull(detailedCheckMinuteInterval, 5))
				and ukey_group = @nServerGroup

			order by serverName

		if isnull(@bSkipNextRun, 0) = 0
		begin
			set @nMinutesSinceLastCheck = dateDiff(minute, @dLastCheck, getDate()) + 30
			set @dLastCheck = getDate()

			-- This way, if one fails with a recoverable error the rest will continue
			-- Plus, we pass in the runtime of the last call so it'll know to look further back
			-- if it's running long
			begin try
				exec pr_examineServer @cServerName, @nMinutesSinceLastCheck
			end try
			begin catch
				if error_message() not like '%since it was compiled%'
				begin
					set @cSubject = 'Failed to make contact with ' + @cServerName
					set @cMessage = 'Failed to make contact with ' + @cServerName + '.<br>' + isnull(error_message(), 'No detail available.')

					insert into notificationLog_stage (subject, message, serverName, severity) values (@cSubject, @cMessage, @cServerName, 1)
				end
			end catch

			update dm_servers with (rowlock)
				set lastDetailedCheck = @dLastCheck
				where serverName = @cServerName
					and isEnabled = 1
					and detailedCheck = 1
		end
		else
			update dm_servers with (rowlock)
				set skipNextRun = 0
				where serverName = @cServerName
					and isEnabled = 1
					and detailedCheck = 1

	end

	insert into notificationLog_history (stepName, ukey_group) values ('END All', @nServerGroup)

end
