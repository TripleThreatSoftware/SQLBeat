-- ================================================================================================
-- Notification.dbo.pr_monitorSMTP
--
-- Scans the Queue, Drop and BadMail folders of designated SMTP servers and alerts on mail needing
-- attention. Job: "Monitor files & SMTP".
-- ================================================================================================
/****** Object:  StoredProcedure [dbo].[pr_monitorSMTP]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_monitorSMTP]
as
begin

	declare @nRowCount int
	declare @cSubject varchar(200)
	declare @cBody varchar(2000)

	create table #messages (messageFile varchar(200))

	insert into #messages
	exec master..xp_cmdshell 'dir /b \\web04\inetpub\mailroot\queue'

	set @nRowCount = @@rowcount

	if @nRowCount > 200
	begin
		set @cSubject = 'Web04 has ' + convert(varchar(20), @nRowCount) + ' emails in the QUEUE folder at ' + convert(varchar(20), getDate(), 120) + '. Please check SMTP service.'
		set @cBody = convert(varchar(20), @nRowCount) + ' emails are in the MAILROOT/QUEUE folder on Web04. Please check SMTP service.'
		insert into [notification].dbo.notificationLog_stage (ymd, subject, message, severity, servername) values (getDate(), @cSubject, @cBody, 1, 'Web04')
	end

	truncate table #messages

	insert into #messages
	exec master..xp_cmdshell 'dir /b \\web04\inetpub\mailroot\drop'

	set @nRowCount = @@rowcount

	if @nRowCount > 200
	begin
		set @cSubject = 'Web04 has ' + convert(varchar(20), @nRowCount) + ' emails in the DROP folder at ' + convert(varchar(20), getDate(), 120) + '. Please check SMTP service.'
		set @cBody = convert(varchar(20), @nRowCount) + ' emails are in the MAILROOT/DROP folder on Web04. Please check SMTP service.'
		insert into [notification].dbo.notificationLog_stage (ymd, subject, message, severity, servername) values (getDate(), @cSubject, @cBody, 1, 'Web04')
	end

	truncate table #messages

	insert into #messages
	exec master..xp_cmdshell 'dir /b \\web04\inetpub\mailroot\badmail'

	set @nRowCount = @@rowcount

	if @nRowCount > 500
	begin
		set @cSubject = 'Web04 has ' + convert(varchar(20), @nRowCount) + ' emails in the BADMAIL folder at ' + convert(varchar(20), getDate(), 120) + '. Please check SMTP service.'
		set @cBody = convert(varchar(20), @nRowCount) + ' emails are in the MAILROOT/BADMAIL folder on Web04. Please check SMTP service.'
		insert into [notification].dbo.notificationLog_stage (ymd, subject, message, severity, servername) values (getDate(), @cSubject, @cBody, 1, 'Web04')
	end


	--This part is for WEB03
	insert into #messages
	exec master..xp_cmdshell 'dir /b \\web03\inetpub\mailroot\queue'

	set @nRowCount = @@rowcount

	if @nRowCount > 200
	begin
		set @cSubject = 'Web03 has ' + convert(varchar(20), @nRowCount) + ' emails in the QUEUE folder at ' + convert(varchar(20), getDate(), 120) + '. Please check SMTP service.'
		set @cBody = convert(varchar(20), @nRowCount) + ' emails are in the MAILROOT/QUEUE folder on Web03. Please check SMTP service.'
		insert into [notification].dbo.notificationLog_stage (ymd, subject, message, severity, servername) values (getDate(), @cSubject, @cBody, 1, 'Web03')
	end

	truncate table #messages

	insert into #messages
	exec master..xp_cmdshell 'dir /b \\web03\inetpub\mailroot\drop'

	set @nRowCount = @@rowcount

	if @nRowCount > 200
	begin
		set @cSubject = 'Web03 has ' + convert(varchar(20), @nRowCount) + ' emails in the DROP folder at ' + convert(varchar(20), getDate(), 120) + '. Please check SMTP service.'
		set @cBody = convert(varchar(20), @nRowCount) + ' emails are in the MAILROOT/DROP folder on Web03. Please check SMTP service.'
		insert into [notification].dbo.notificationLog_stage (ymd, subject, message, severity, servername) values (getDate(), @cSubject, @cBody, 1, 'Web03')
	end

	truncate table #messages

	insert into #messages
	exec master..xp_cmdshell 'dir /b \\web03\inetpub\mailroot\badmail'

	set @nRowCount = @@rowcount

	if @nRowCount > 500
	begin
		set @cSubject = 'Web03 has ' + convert(varchar(20), @nRowCount) + ' emails in the BADMAIL folder at ' + convert(varchar(20), getDate(), 120) + '. Please check SMTP service.'
		set @cBody = convert(varchar(20), @nRowCount) + ' emails are in the MAILROOT/BADMAIL folder on Web03. Please check SMTP service.'
		insert into [notification].dbo.notificationLog_stage (ymd, subject, message, severity, servername) values (getDate(), @cSubject, @cBody, 1, 'Web03')
	end
end
GO
