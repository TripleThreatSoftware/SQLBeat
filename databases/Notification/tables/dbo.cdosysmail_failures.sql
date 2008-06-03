IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[sp_send_cdosysmail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE  PROCEDURE [sp_send_cdosysmail]
	@From varchar(100) ,
	@To varchar(100) ,
	@Subject varchar(100)=" ",
	@Body varchar(8000) =" "
	/*********************************************************************

	This stored procedure takes the parameters and sends an e-mail.
	All the mail configurations are hard-coded in the stored procedure.
	Comments are added to the stored procedure where necessary.
	References to the CDOSYS objects are at the following MSDN Web site:
	http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cdosys/html/_cdosys_messaging.asp

	***********************************************************************/
AS
begin
	Declare @iMsg int
	Declare @hr int
	Declare @source varchar(255)
	Declare @description varchar(500)
	Declare @output varchar(1000)
	declare @cSMTPServer varchar(200)
	set @cSMTPServer = (select settingValue from dm_settings where settingName = ''SMTP Server'')

	if not exists (select * from dbo.sysobjects where [name] = ''cdosysmail_failures'')
	BEGIN
		CREATE TABLE [cdosysmail_failures] (
			[Date of Failure] [datetime] NULL ,
			[Spid] [int] NULL ,
			[From] [varchar] (100) NULL ,
			[To] [varchar] (100) NULL ,
			[Subject] [varchar] (100) NULL ,
			[Body] [varchar] (8000) NULL ,
			[iMsg] [int] NULL ,
			[Hr] [int] NULL ,
			[Source of Failure] [varchar] (255) NULL ,
			[Description of Failure] [varchar] (500) NULL ,
			[Output from Failure] [varchar] (1000) NULL ,
			[Comment about Failure] [varchar] (50) NULL
		)
	END

	--************* Create the CDO.Message Object ************************
	EXEC @hr = sp_OACreate ''CDO.Message'', @iMsg OUT
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OACreate'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OACreate'')
			RETURN
		END
		ELSE
	 	BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		RETURN
	 	END
	END

	--***************Configuring the Message Object ******************
	-- This is to configure a remote SMTP server.
	-- http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cdosys/html/_cdosys_schema_configuration_sendusing.asp
	EXEC @hr = sp_OASetProperty @iMsg, ''Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusing").Value'',''2''
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OASetProperty sendusing'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OASetProperty sendusing'')
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
	 	BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		GOTO send_cdosysmail_cleanup
	 	END
	END
	-- This is to configure the Server Name or IP address.
	-- Replace MailServerName by the name or IP of your SMTP Server.
	EXEC @hr = sp_OASetProperty @iMsg, ''Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserver").Value'', @cSMTPServer
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OASetProperty smtpserver'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OASetProperty smtpserver'')
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
	 	BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		GOTO send_cdosysmail_cleanup
	 	END
	END

	-- Save the configurations to the message object.
	EXEC @hr = sp_OAMethod @iMsg, ''Configuration.Fields.Update'', null
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OASetProperty Update'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OASetProperty Update'')
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
	 	BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		GOTO send_cdosysmail_cleanup
	 	END
	END

	-- Set the e-mail parameters.
	EXEC @hr = sp_OASetProperty @iMsg, ''To'', @To
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OASetProperty To'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OASetProperty To'')
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
	 	BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		GOTO send_cdosysmail_cleanup
	 	END
	END

	EXEC @hr = sp_OASetProperty @iMsg, ''From'', @From
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OASetProperty From'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OASetProperty From'')
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
	 	BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		GOTO send_cdosysmail_cleanup
	 	END
	END

	EXEC @hr = sp_OASetProperty @iMsg, ''Subject'', @Subject
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OASetProperty Subject'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OASetProperty Subject'')
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
		BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		GOTO send_cdosysmail_cleanup
	 	END
	END

	-- If you are using HTML e-mail, use ''HTMLBody'' instead of ''TextBody''.
	EXEC @hr = sp_OASetProperty @iMsg, ''TextBody'', @Body
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OASetProperty TextBody'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OASetProperty TextBody'')
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
	 	BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		GOTO send_cdosysmail_cleanup
	 	END
	END

	EXEC @hr = sp_OAMethod @iMsg, ''Send'', NULL
	IF @hr <>0
	BEGIN
		SELECT @hr
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OAMethod Send'')
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @output = ''  Source: '' + @source
			PRINT  @output
			SELECT @output = ''  Description: '' + @description
			PRINT  @output
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OAMethod Send'')
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
	 	BEGIN
	   		PRINT ''  sp_OAGetErrorInfo failed.''
	   		GOTO send_cdosysmail_cleanup
	 	END
	END


	-- Do some error handling after each step if you have to.
	-- Clean up the objects created.
	send_cdosysmail_cleanup:
	If (@iMsg IS NOT NULL) -- if @iMsg is NOT NULL then destroy it
	BEGIN
		EXEC @hr=sp_OADestroy @iMsg

		-- handle the failure of the destroy if needed
		IF @hr <>0
			BEGIN
			select @hr
		        INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''Failed at sp_OADestroy'')
				EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT

			-- if sp_OAGetErrorInfo was successful, print errors
			IF @hr = 0
			BEGIN
				SELECT @output = ''  Source: '' + @source
			        PRINT  @output
			        SELECT @output = ''  Description: '' + @description
			        PRINT  @output
				INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''sp_OAGetErrorInfo for sp_OADestroy'')
			END

			-- else sp_OAGetErrorInfo failed
			ELSE
			BEGIN
				PRINT ''  sp_OAGetErrorInfo failed.''
			        RETURN
			END
		END
	END
	ELSE
	BEGIN
		PRINT '' sp_OADestroy skipped because @iMsg is NULL.''
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, ''@iMsg is NULL, sp_OADestroy skipped'')
		RETURN
	END
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_dashboard_serverStatus]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE procedure [pr_dashboard_serverStatus] (@cUserName varchar(100))
as
begin

	declare @cServerName varchar(200)
	declare @cSQLString nvarchar(4000)

	create table #messages (serverName varchar(200), messageText varchar(2000), severity int)

	set @cSQLString = ''select @@serverName as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode from notification.dbo.dm_servers''

	select top 0 convert(varchar(200), space(0)) as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode
		into #serverList
		from dm_servers
		where isEnabled = 1

	set @cServerName = ''''

	while exists (select top 1 settingValue from dm_settings where settingName like ''%sister server%'' and settingValue > @cServerName)
	begin
		select top 1 @cServerName = settingValue
			from dm_settings
			where settingName like ''%sister server%''
				and settingValue > @cServerName
			order by settingValue

		set @cSQLString = @cSQLString + char(13) + ''union select '' + char(39) + @cServerName + char(39) + '' as monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode from ['' + @cServerName + ''].notification.dbo.dm_servers''
	end

	print @cSQLString

	insert into #serverList (monitorServer, serverName,friendlyName,offHoursPriority,ukey_group,skipNextRun,isEnabled,configurationCheck,detailedCheck,eventLogCheck,fragmentationCheck,installedSoftwareCheck,integrityCheck,pingCheck,securityCheck,serviceCheck,statisticsCheck,username,password,wmiUsername,wmiPassword,lastConfigurationCheck,lastDetailedCheck,lastEventLogCheck,lastFragmentationCheck,lastInstalledSoftwareCheck,lastIntegrityCheck,lastPingCheck,lastSecurityCheck,lastServiceCheck,configurationCheckMinuteInterval,detailedCheckMinuteInterval,eventLogCheckMinuteInterval,fragmentationCheckMinuteInterval,installedSoftwareCheckMinuteInterval,integrityCheckMinuteInterval,pingCheckMinuteInterval,securityCheckMinuteInterval,serviceCheckMinuteInterval,statisticsCheckMinuteInterval,isServerPingable,isSQLServiceRunning,isSQLAgentServiceRunning,serverVersion,summarizeOffHoursJobFailures,ignoreTimeouts,includeInLongRunningQueries,wmiStatus,architecture,lowSpaceThreshold,lowVirtualMemoryThreshold,lowPhysicalMemoryThreshold,lowPoolNonpagedBytesThreshold,lowPoolPagedBytesThreshold,lowspaceThresholdRelative,silenceUntil,eventLogCheckSleepUntil, isSQLBox, isClusterNode)
	exec sp_executeSQL @cSQLString

	select distinct serverName
		into #allServers
		from #serverList

	delete from #serverList where isEnabled = 0

	--**********************************************************************************************
	-- Generate all possible messages
	-- This is a mess. Because servers may be monitored by more than one monitor box, we need to
	-- discount each message if any one of the monitor boxes performs the function.
	--**********************************************************************************************

	insert into #messages (serverName, messageText, severity)
	select a.serverName, b.messageText, b.severity
		from #allServers a,
			(
				select ''Server is not monitored.'' as messageText, 1 as severity
				union
				select ''Server is not WMI accessible.'' as messageText, 1 as severity
				union
				select ''Server is not pingable.'' as messageText, 1 as severity
				union
				select ''Server is not PING checked.'' as messageText, 1 as severity
				union
				select ''Server is WMI available but EventLog is not checked.'' as messageText, 2 as severity
				union
				select ''Server is WMI available but Installed Software is not checked.'' as messageText, 2 as severity
				union
				select ''Server is WMI available but Configuration is not checked.'' as messageText, 2 as severity
				union
				select ''Server is a SQL box but detailed checks are not performed.'' as messageText, 2 as severity
				union
				select ''Server is a SQL box but service checks are not performed.'' as messageText, 2 as severity
				union
				select ''Server is a SQL box but fragmentation scans are not performed.'' as messageText, 3 as severity
				union
				select ''Server is a SQL box but database integrity checks are not performed.'' as messageText, 3 as severity
				union
				select ''Server is a SQL box but server-level statistics checks are not performed.'' as messageText, 3 as severity
				union
				select ''EventLog checks have been snoozed.'' as messageText, 3 as severity
				union
				select ''PING checks are being performed by more than one monitor box.'' as messageText, 3 as severity
				union
				select ''SQL checks are being performed by more than one monitor box.'' as messageText, 3 as severity
				union
				select ''WMI checks are being performed by more than one monitor box.'' as messageText, 3 as severity
				) b

	--**********************************************************************************************
	-- Remove messages that do not apply
	--**********************************************************************************************

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
		where a.messageText = ''Server is not monitored.''

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and pingCheck = 1 then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = ''PING checks are being performed by more than one monitor box.''

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and detailedCheck = 1 and isSQLBox = 1 then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = ''SQL checks are being performed by more than one monitor box.''

	delete #messages
		from #messages a
		join (
			select serverName
				from #serverList
				group by serverName
				having sum(case when isEnabled = 1 and eventLogCheck = 1 and wmiStatus = ''success'' then 1 else 0 end) <= 1
			)b on a.serverName = b.serverName
		where a.messageText = ''WMI checks are being performed by more than one monitor box.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.wmiStatus = ''success''
		where a.messageText = ''Server is not WMI accessible.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.pingCheck = 1
		where a.messageText = ''Server is not PING checked.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
		where a.messageText = ''Server is not pingable.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = ''success''
			and b.eventLogCheck = 1
		where a.messageText = ''Server is WMI available but EventLog is not checked.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = ''success''
			and b.eventLogCheck = 1
			and (b.eventLogCheckSleepUntil is null or b.eventLogCheckSleepUntil < getDate())
		where a.messageText = ''EventLog checks have been snoozed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = ''success''
			and b.installedSoftwareCheck = 1
		where a.messageText = ''Server is WMI available but Installed Software is not checked.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.wmiStatus = ''success''
			and b.configurationCheck = 1
		where a.messageText = ''Server is WMI available but Configuration is not checked.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.detailedCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but detailed checks are not performed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.serviceCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but service checks are not performed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.fragmentationCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but fragmentation scans are not performed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.fragmentationCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but database integrity checks are not performed.''

	delete #messages
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and b.isServerPingable = 1
			and b.isSQLBox = 1
			and b.statisticsCheck = 1
			and b.isClusterNode = 0
		where a.messageText = ''Server is a SQL box but server-level statistics checks are not performed.''

	--**********************************************************************************************
	-- Message cleanup
	--**********************************************************************************************

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = ''Server is not pingable.''
		where a.messageText <> ''Server is not pingable.''

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = ''Server is not monitored.''
		where a.messageText <> ''Server is not monitored.''

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = ''Server is WMI available but EventLog is not checked.''
		where a.messageText in (''EventLog checks have been snoozed.'')

	delete a
		from #messages a
		join #messages b on a.serverName = b.serverName
			and b.messageText = ''Server is not WMI accessible.''
		where a.messageText in (''Server is WMI available but EventLog is not checked.'',
			''Server is WMI available but Installed Software is not checked.'',
			''Server is WMI available but Configuration is not checked.'',
			''EventLog checks have been snoozed.'')

	delete a
		from #messages a
		join #serverList b on a.serverName = b.serverName
			and (b.isSQLBox = 0 or b.isClusterNode = 1)
		where a.messageText in (''Server is a SQL box but detailed checks are not performed.'',
			''Server is a SQL box but service checks are not performed.'',
			''Server is a SQL box but fragmentation scans are not performed.'',
			''Server is a SQL box but database integrity checks are not performed.'',
			''Server is a SQL box but server-level statistics checks are not performed.'')

	delete #messages
		from #messages a
		join messageRules b on (a.serverName like ''%'' + b.serverLike + ''%'' or isnull(b.serverLike, '''') = '''')
			and (a.serverName = b.serverEquals or isnull(b.serverEquals, '''') = '''')
			and (a.messageText like ''%'' + b.messageLike + ''%'' or isnull(b.messageLike, '''') = '''')
			and b.userName = @cUsername
			and b.isMonitorMessage = 1

	select *, ''configureAlerts.aspx?action=silence&source=serverStatus&serverName='' + serverName + ''&message="'' + messageText + ''"'' as hyperlink
		from #messages
		order by serverName, severity, messageText

	drop table #serverList
	drop table #messages
	drop table #allServers
end
-- exec pr_dashboard_serverStatus ''cole''
-- select * from messageRules
-- delete from messageRules where ukey = 11
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
