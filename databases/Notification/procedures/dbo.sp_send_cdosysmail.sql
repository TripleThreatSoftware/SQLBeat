/****** Object:  StoredProcedure [dbo].[sp_send_cdosysmail]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[sp_send_cdosysmail]
	@From varchar(100) ,
	@To varchar(100) ,
	@Subject varchar(5000)=" ",
	@Body varchar(max) =" ",
	@AttachmentPath varchar(1000) = " ",
	@HTMLBody varchar(max) =" "

	/*********************************************************************

	A much prettier version is available at at the following MSDN Web site:
	http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cdosys/html/_cdosys_messaging.asp

	***********************************************************************/
AS
begin
	Declare @iMsg int
	Declare @nResultCode int
	Declare @nResultCode2 int
	Declare @cSource varchar(255)
	Declare @cDescription varchar(500)
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

	--print @cSMTPServer
	--print @cSMTPUserName
	--print @cSMTPPassword
	--print @cSMTPPort
	--print @bSMTPUseSSL

	if isnull(@cSMTPPort, '') in ('0', '')
		set @cSMTPPort = null

	--************* Create the CDO.Message Object ************************
	EXEC @nResultCode = sp_OACreate 'CDO.Message', @iMsg OUT

	EXEC @nResultCode = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusing").Value', '2'
	EXEC @nResultCode = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserver").Value', @cSMTPServer
	EXEC @nResultCode = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserverport").Value', @cSMTPPort
	if @cSMTPUserName <> ''
		EXEC @nResultCode = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate").Value', '1'

	if @bSMTPUseSSL = 1
		EXEC @nResultCode = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpusessl").Value', 'True'

	if @cSMTPUserName <> ''
		EXEC @nResultCode = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusername").Value', @cSMTPUserName
	if @cSMTPUserName <> ''
		EXEC @nResultCode = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendpassword").Value', @cSMTPPassword

	-- Save the configurations to the message object.
	EXEC @nResultCode = sp_OAMethod @iMsg, 'Configuration.Fields.Update', null

	-- Set the e-mail parameters.
	EXEC @nResultCode = sp_OASetProperty @iMsg, 'To', @To
	EXEC @nResultCode = sp_OASetProperty @iMsg, 'From', @From
	EXEC @nResultCode = sp_OASetProperty @iMsg, 'Subject', @Subject

	-- If you are using HTML e-mail, use 'HTMLBody' instead of 'TextBody'.
	if isnull(@HTMLBody, '') <> ''
		EXEC @nResultCode = sp_OASetProperty @iMsg, 'HTMLBody', @HTMLBody
	else
		EXEC @nResultCode = sp_OASetProperty @iMsg, 'TextBody', @Body

	if rtrim(ltrim(isnull(@AttachmentPath, ''))) <> ''
		EXEC @nResultCode = sp_OAMethod @iMsg, 'AddAttachment', @output out, @AttachmentPath

	EXEC @nResultCode = sp_OAMethod @iMsg, 'Send', NULL

	-- alter table messagesSent add resultCode int
	-- select top 100 * from messagesSent

	IF @nResultCode <> 0
	BEGIN
		-- failure

		EXEC @nResultCode2 = sp_OAGetErrorInfo NULL, @cSource OUT, @cDescription OUT

		if isnull(@HTMLBody, '') <> ''
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @HTMLBody, @iMsg, @nResultCode, @cSource, @cDescription, @output, 'Failed at Send')
		else
			INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @nResultCode, @cSource, @cDescription, @output, 'Failed at Send')

	END
	else
	begin
		-- success

		if isnull(@HTMLBody, '') <> ''
			insert into messagesSent (recipient, sender, subject, body, resultCode) values (@To, @From, @Subject, @HTMLBody, @nResultCode)
		else
			insert into messagesSent (recipient, sender, subject, body, resultCode) values (@To, @From, @Subject, @Body, @nResultCode)
	end


	-- Do some error handling after each step if you have to.
	-- Clean up the objects created.

	If (@iMsg IS NOT NULL) -- if @iMsg is NOT NULL then destroy it
	BEGIN
		EXEC @nResultCode = sp_OADestroy @iMsg

		-- handle the failure of the destroy if needed
		IF @nResultCode <> 0
		BEGIN
			EXEC @nResultCode2 = sp_OAGetErrorInfo NULL, @cSource OUT, @cDescription OUT

		    INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @nResultCode, @cSource, @cDescription, @output, 'Failed at sp_OADestroy')
		END
	END
	ELSE
	BEGIN

		INSERT INTO [dbo].[cdosysmail_failures] VALUES (getdate(), @@spid, @From, @To, @Subject, @Body, @iMsg, @nResultCode, null, null, @output, '@iMsg is NULL, sp_OADestroy skipped')
		RETURN
	END
end
GO
