/****** Object:  StoredProcedure [dbo].[pr_dashboard_silenceAlert]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from messageRules
-- update messageRules set ukey_userEmail = 0 where ukey_userEmail is null
CREATE procedure [dbo].[pr_dashboard_silenceAlert] (@cUserName varchar(100), @cServerName varchar(100), @cMessage varchar(500), @cMessageSource varchar(100))
as
begin
	declare @bIsJobFailure bit
	declare @bIsLongRunningJob bit
	declare @bIsBlocking bit
	declare @bIsLongRunningProcess bit
	declare @bIsDriveSpace bit
	declare @bIsLogSize bit
	declare @bIsEventLog bit
	declare @bIsService bit
	declare @bIsConnectivity bit
	declare @bIsConfiguration bit
	declare @bIsInstalledSoftware bit
	declare @bIsFulfillment bit
	declare @bIsMonitorMessage bit

	set @bIsJobFailure = 0
	set @bIsLongRunningJob = 0
	set @bIsBlocking = 0
	set @bIsLongRunningProcess = 0
	set @bIsDriveSpace = 0
	set @bIsLogSize = 0
	set @bIsEventLog = 0
	set @bIsService = 0
	set @bIsConnectivity = 0
	set @bIsConfiguration = 0
	set @bIsInstalledSoftware = 0
	set @bIsFulfillment = 0
	set @bIsMonitorMessage = 0

	set @cMessage = replace(@cMessage, '"', '')

	if @cMessageSource = 'serverStatus'
		set @bIsMonitorMessage = 1

	if not exists (
		select top 1 *
			from messageRules
			where userName = @cUserName
				and serverEquals = @cServerName
				and messageLike = @cMessage
				and doNotSendMessage = 1
				and isJobFailure = @bIsJobFailure
				and isLongRunningJob = @bIsLongRunningJob
				and isBlocking = @bIsBlocking
				and isLongRunningProcess = @bIsLongRunningProcess
				and isDriveSpace = @bIsDriveSpace
				and isLogSize = @bIsLogSize
				and isEventLog = @bIsEventLog
				and isService = @bIsService
				and isConnectivity = @bIsConnectivity
				and isConfiguration = @bIsConfiguration
				and isInstalledSoftware = @bIsInstalledSoftware
				and isFulfillment = @bIsFulfillment
				and isMonitorMessage = @bIsMonitorMessage
		)
	begin
		insert into messageRules (userName, serverEquals, messageLike, doNotSendMessage, ukey_userEmail,
				isJobFailure, isLongRunningJob, isBlocking, isLongRunningProcess, isDriveSpace, isLogSize,
				isEventLog, isService, isConnectivity, isConfiguration, isInstalledSoftware, isFulfillment, isMonitorMessage)
			values (@cUserName, @cServerName, @cMessage, 1, 0,
				@bIsJobFailure, @bIsLongRunningJob, @bIsBlocking, @bIsLongRunningProcess, @bIsDriveSpace, @bIsLogSize,
				@bIsEventLog, @bIsService, @bIsConnectivity, @bIsConfiguration, @bIsInstalledSoftware, @bIsFulfillment, @bIsMonitorMessage
			)
	end
end


--alter table messageRules add constraint pk_messageRules_ukey primary key (ukey)
GO
