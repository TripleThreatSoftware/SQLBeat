use notification
go

create procedure pr_monitorSMTP
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
end
