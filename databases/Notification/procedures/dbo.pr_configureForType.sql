/****** Object:  StoredProcedure [dbo].[pr_configureForType]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_configureForType 'web03', 'SQL Server'
CREATE procedure [dbo].[pr_configureForType] (@cServerName varchar(100), @cServerType varchar(100), @nUkeyGroup int = 0, @bEnableWMI bit = 1,
	@cSQLUsername varchar(500) = '', @cSQLPassword varchar(500) = '', @cWMIUsername varchar(500) = '', @cWMIPassword varchar(500) = '')
as
begin
	declare @bIsProduction bit
	declare @nUkeyServer int
	declare @cConfigurationProfile varchar(500)

	set @cConfigurationProfile = ''

	set @nUkeyServer = (select top 1 ukey from dm_servers (nolock) where serverName = @cServerName)

	if isnull(@nUkeyGroup, 0) = 0
		set @nUkeyGroup = (select top 1 ukey_group from dm_servers (nolock) where serverName = @cServerName)

	if isnull(@nUkeyServer, 0) = 0
	begin
		insert into dm_servers (serverName, ukey_group) values (@cServerName, @nUkeyGroup)
		set @nUkeyServer = scope_identity()
	end

	set @bIsProduction = (select top 1 isProduction from dm_serverGroups (nolock) where ukey = @nUkeyGroup)

	if @cServerType = 'SQL Server'
	begin
		update dm_servers with (rowlock)
			set isEnabled = 1,
				detailedCheck = 1,
				detailedCheckMinuteInterval = 2,
				eventLogCheck = case when @bEnableWMI = 1 then 1 else 0 end,
				eventLogCheckMinuteInterval = 10,
				configurationCheck = case when @bEnableWMI = 1 then 1 else 0 end,
				configurationCheckMinuteInterval = 10,
				isSQLBox = 1,
				isClusterNode = 0,
				fragmentationCheck = 0,
				fragmentationCheckMinuteInterval = 60*24*7,
				integrityCheck = 1,
				integrityCheckMinuteInterval = 60*24*7,
				statisticsCheck = 1,
				statisticsCheckMinuteInterval = 30,
				isServerPingable = 1,
				isSQLServiceRunning = 1,
				isSQLAgentServiceRunning = 1,
				pingCheck = 1,
				pingCheckMinuteInterval = 2,
				ignoreTimeouts = 0,
				architecture = '32',
				deepSQL2005Check = 1,
				deepSQL2005CheckMinuteInterval = 60,
				objectChangeCheck = 1,
				objectCheckMinuteInterval = 60*24,
				tableSizeCheck = 1,
				tableSizeCheckMinuteInterval = 60*24,
				indexCheck = 1,
				indexCheckMinuteInterval = 60*24,
				checkLogFileSize = 1,
				checkOrphanedUsers = 1,
				checkExecutionStats = 1,
				maintenanceWindowStart = '1900-01-01 02:00:00.000',
				maintenanceWindowStop = '1900-01-01 05:00:00.000',

				userName = @cSQLUsername,
				password = @cSQLPassword,
				wmiUserName = @cWMIUsername,
				wmiPassword = @cWMIPassword
			where ukey = @nUkeyServer

		set @cConfigurationProfile = 'SQL Server - Production'
	end

	if @cServerType = 'IIS Web Server'
	begin
		update dm_servers with (rowlock)
			set isEnabled = 1,
				pingCheck = 1,
				pingCheckMinuteInterval = 2,
				isIIS = 1,
				configurationCheck = case when @bEnableWMI = 1 then 1 else 0 end,
				configurationCheckMinuteInterval = 10,
				eventLogCheck = case when @bEnableWMI = 1 then 1 else 0 end,
				eventLogCheckMinuteInterval = 10,
				isServerPingable = 1,
				maintenanceWindowStart = '1900-01-01 02:00:00.000',
				maintenanceWindowStop = '1900-01-01 05:00:00.000',

				userName = @cSQLUsername,
				password = @cSQLPassword,
				wmiUserName = @cWMIUsername,
				wmiPassword = @cWMIPassword
			where ukey = @nUkeyServer

		set @cConfigurationProfile = 'Web Server - Production'
	end

	if @cServerType = 'Server'
	begin
		update dm_servers with (rowlock)
			set isEnabled = 1,
				pingCheck = 1,
				pingCheckMinuteInterval = 2,
				configurationCheck = case when @bEnableWMI = 1 then 1 else 0 end,
				configurationCheckMinuteInterval = 10,
				eventLogCheck = case when @bEnableWMI = 1 then 1 else 0 end,
				eventLogCheckMinuteInterval = 10,
				isServerPingable = 1,
				maintenanceWindowStart = '1900-01-01 02:00:00.000',
				maintenanceWindowStop = '1900-01-01 05:00:00.000',

				userName = @cSQLUsername,
				password = @cSQLPassword,
				wmiUserName = @cWMIUsername,
				wmiPassword = @cWMIPassword
			where ukey = @nUkeyServer

		set @cConfigurationProfile = 'Server - Production'
	end

	-- now, configure the WMI profile
	if @bEnableWMI = 1 and isnull(@cConfigurationProfile, '') <> ''
	begin
		exec configuration.dbo.pr_configureForProfile @cServerName, @cConfigurationProfile
	end
end
GO
