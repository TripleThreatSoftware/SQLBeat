SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER  PROCEDURE [dbo].[sp_send_cdosysmail]
	@From varchar(100) ,
	@To varchar(100) ,
	@Subject varchar(100)=" ",
	@Body varchar(8000) =" ",
	@AttachmentPath varchar(1000) = " "

	/*********************************************************************

	A much prettier version is available at at the following MSDN Web site:
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
	declare @cSMTPUserName varchar(200)
	declare @cSMTPPassword varchar(200)
	declare @cSMTPPort varchar(200)
	declare @bSMTPUseSSL bit

	set @cSMTPServer = (select top 1 settingValue from dm_settings where settingName = 'SMTP Server')
	set @cSMTPUserName = (select top 1 settingValue from dm_settings where settingName = 'SMTP User Name')
	set @cSMTPPassword = (select top 1 settingValue from dm_settings where settingName = 'SMTP Password')
	set @cSMTPPort = (select top 1 settingValue from dm_settings where settingName = 'SMTP Port')
	set @bSMTPUseSSL = (select top 1 convert(bit, settingValue) from dm_settings where settingName = 'SMTP SSL')

	--************* Create the CDO.Message Object ************************
	EXEC @hr = sp_OACreate 'CDO.Message', @iMsg OUT

	EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusing").Value', '2'
	EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserver").Value', @cSMTPServer
	EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserverport").Value', @cSMTPPort
	if @cSMTPUserName <> ''
		EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate").Value', '1'

	if @bSMTPUseSSL = 1
		EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpusessl").Value', 'True'

	if @cSMTPUserName <> ''
		EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusername").Value', @cSMTPUserName
	if @cSMTPUserName <> ''
		EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendpassword").Value', @cSMTPPassword

	-- Save the configurations to the message object.
	EXEC @hr = sp_OAMethod @iMsg, 'Configuration.Fields.Update', null

	-- Set the e-mail parameters.
	EXEC @hr = sp_OASetProperty @iMsg, 'To', @To
	EXEC @hr = sp_OASetProperty @iMsg, 'From', @From
	EXEC @hr = sp_OASetProperty @iMsg, 'Subject', @Subject

	-- If you are using HTML e-mail, use 'HTMLBody' instead of 'TextBody'.
	EXEC @hr = sp_OASetProperty @iMsg, 'TextBody', @Body

	EXEC @hr = sp_OAMethod @iMsg, 'AddAttachment', @output out, @AttachmentPath

	EXEC @hr = sp_OAMethod @iMsg, 'Send', NULL

	IF @hr <>0
	BEGIN
		select 'error'
		EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
		IF @hr = 0
	 	BEGIN
			SELECT @source as source, @description as description
			GOTO send_cdosysmail_cleanup
	 	END
		ELSE
	 	BEGIN
	   		PRINT '  sp_OAGetErrorInfo failed.'
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
		        INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, 'Failed at sp_OADestroy')
				EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT

			-- if sp_OAGetErrorInfo was successful, print errors
			IF @hr = 0
			BEGIN
				SELECT @output = '  Source: ' + @source
			        PRINT  @output
			        SELECT @output = '  Description: ' + @description
			        PRINT  @output
				INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, 'sp_OAGetErrorInfo for sp_OADestroy')
			END

			-- else sp_OAGetErrorInfo failed
			ELSE
			BEGIN
				PRINT '  sp_OAGetErrorInfo failed.'
			        RETURN
			END
		END
	END
	ELSE
	BEGIN
		PRINT ' sp_OADestroy skipped because @iMsg is NULL.'
		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @hr, @source, @description, @output, '@iMsg is NULL, sp_OADestroy skipped')
		RETURN
	END
end
