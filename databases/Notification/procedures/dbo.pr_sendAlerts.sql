USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_sendAlerts]    Script Date: 08/27/2008 09:36:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_sendAlerts 'cole', 1
-- exec pr_sendAlerts '', 0
ALTER procedure [dbo].[pr_sendAlerts] (@cUserName varchar(100) = '', @bIsPreview bit = 0)
as
begin
	set nocount off

--declare @cUserName varchar(100), @bIsPreview bit
--set @cUserName = null
--set @bIsPreview = 0

	declare @bIsBusinessHours bit
	declare @nUkeyMessage int
	declare @cThisSubject varchar(1000)
	declare @cThisMessage varchar(8000)
	declare @cEmailAddress varchar(200)

	set @bIsPreview = isnull(@bIsPreview, 0)

	if dbo.fn_isBusinessHours() = 1
		set @bIsBusinessHours = 1
	else
		set @bIsBusinessHours = 0

	select
		b.ukey as ukey_rule, b.userName, c.emailAddress, a.*
		into #messages
		from notificationLog a
		join messageRules b on
			(a.serverName = b.serverEquals or isnull(b.serverEquals, '') = '')
			and (a.serverName like '%' + b.serverLike + '%' or isnull(b.serverLike, '') = '')
			and (a.message like '%' + b.messageLike + '%' or isnull(b.messageLike, '') = '')
			and (a.subject like '%' + b.subjectLike + '%' or isnull(b.subjectLike, '') = '')
			and (a.severity = b.severity or isnull(b.severity, 0) = 0)
			and (
				isnull(b.allMessages, 0) = 1
				or (a.isJobFailure = b.isJobFailure and isnull(b.isJobFailure, 0) = 1)
				or (a.isLongRunningJob = b.isLongRunningJob and isnull(b.isLongRunningJob, 0) = 1)
				or (a.isBlocking = b.isBlocking and isnull(b.isBlocking, 0) = 1)
				or (a.isLongRunningProcess = b.isLongRunningProcess and isnull(b.isLongRunningProcess, 0) = 1)
				or (a.isDriveSpace = b.isDriveSpace and isnull(b.isDriveSpace, 0) = 1)
				or (a.isLogSize = b.isLogSize and isnull(b.isLogSize, 0) = 1)
				or (a.isEventLog = b.isEventLog and isnull(b.isEventLog, 0) = 1)
				or (a.isService = b.isService and isnull(b.isService, 0) = 1)
				or (a.isConnectivity = b.isConnectivity and isnull(b.isConnectivity, 0) = 1)
				or (a.isConfiguration = b.isConfiguration and isnull(b.isConfiguration, 0) = 1)
				or (a.isInstalledSoftware = b.isInstalledSoftware and isnull(b.isInstalledSoftware, 0) = 1)
				or (a.isMonitorMessage = b.isMonitorMessage and isnull(b.isMonitorMessage, 0) = 1)
				or (
					isnull(b.isMonitorMessage, 0) = 0
					and isnull(b.isInstalledSoftware, 0) = 0
					and isnull(b.isConfiguration, 0) = 0
					and isnull(b.isDriveSpace, 0) = 0
					and isnull(b.isConnectivity, 0) = 0
					and isnull(b.isService, 0) = 0
					and isnull(b.isEventLog, 0) = 0
					and isnull(b.isLogSize, 0) = 0
					and isnull(b.isLongRunningProcess, 0) = 0
					and isnull(b.isBlocking, 0) = 0
					and isnull(b.isLongRunningJob, 0) = 0
					and isnull(b.isJobFailure, 0) = 0
					)
				)
			and isnull(b.sendMessage, 0) = 1
			and (
				(businessHours = 1 and @bIsBusinessHours = 1)
				or (offHours = 1 and @bIsBusinessHours = 0)
--				or (businessHours = 0 and offHours = 0)
				or @bIsPreview = 1
				or isnull(businessHours, 0) = 0
				)
			and (b.userName = @cUserName or isnull(@cUserName, '') = '')
		join userEmails c on b.ukey_userEmail = c.ukey
		left outer join dm_servers d on a.serverName = d.serverName
		where (
				b.ukey_group = d.ukey_group
				or isnull(b.ukey_group, 0) = 0
--				or isnull(d.ukey_group, 0) = 0
				)
			and a.ymd >= dateAdd(hour, -72, getdate())

	delete #messages
		from #messages a
		join messageRules b on
			(a.serverName = b.serverEquals or b.serverEquals is null)
			and (a.serverName like '%' + b.serverLike + '%' or b.serverLike is null)
			and (a.message like '%' + b.messageLike + '%' or b.messageLike is null)
			and (a.subject like '%' + b.subjectLike + '%' or b.subjectLike is null)
			and (a.severity = b.severity or isnull(b.severity, 0) = 0)
			and (
				isnull(b.allMessages, 0) = 1
				or (a.isJobFailure = b.isJobFailure and isnull(b.isJobFailure, 0) = 1)
				or (a.isLongRunningJob = b.isLongRunningJob and isnull(b.isLongRunningJob, 0) = 1)
				or (a.isBlocking = b.isBlocking and isnull(b.isBlocking, 0) = 1)
				or (a.isLongRunningProcess = b.isLongRunningProcess and isnull(b.isLongRunningProcess, 0) = 1)
				or (a.isDriveSpace = b.isDriveSpace and isnull(b.isDriveSpace, 0) = 1)
				or (a.isLogSize = b.isLogSize and isnull(b.isLogSize, 0) = 1)
				or (a.isEventLog = b.isEventLog and isnull(b.isEventLog, 0) = 1)
				or (a.isService = b.isService and isnull(b.isService, 0) = 1)
				or (a.isConnectivity = b.isConnectivity and isnull(b.isConnectivity, 0) = 1)
				or (a.isConfiguration = b.isConfiguration and isnull(b.isConfiguration, 0) = 1)
				or (a.isInstalledSoftware = b.isInstalledSoftware and isnull(b.isInstalledSoftware, 0) = 1)
				or (a.isMonitorMessage = b.isMonitorMessage and isnull(b.isMonitorMessage, 0) = 1)
				or (
					isnull(b.isMonitorMessage, 0) = 0
					and isnull(b.isInstalledSoftware, 0) = 0
					and isnull(b.isConfiguration, 0) = 0
					and isnull(b.isDriveSpace, 0) = 0
					and isnull(b.isConnectivity, 0) = 0
					and isnull(b.isService, 0) = 0
					and isnull(b.isEventLog, 0) = 0
					and isnull(b.isLogSize, 0) = 0
					and isnull(b.isLongRunningProcess, 0) = 0
					and isnull(b.isBlocking, 0) = 0
					and isnull(b.isLongRunningJob, 0) = 0
					and isnull(b.isJobFailure, 0) = 0
					)
				)
			and isnull(b.doNotSendMessage, 0) = 1
			and (
					(
						(businessHours = 1 and @bIsBusinessHours = 1)
						or (offHours = 1 and @bIsBusinessHours = 0)
						or (businessHours = 0 and offHours = 0)
						or isnull(businessHours, 0) = 0
						)
				)
			and (b.userName = a.userName or b.userName is null)
		left outer join dm_servers d on a.serverName = d.serverName
		where (
			b.ukey_group = d.ukey_group
			or isnull(b.ukey_group, 0) = 0
--			or isnull(d.ukey_group, 0) = 0
			)

	select distinct a.serverName, a.userName, a.emailAddress, a.subject, a.message, a.ukey as ukey_notification, a.ymd,
		identity(int) as ukey
		into #messagesToSend
		from #messages a
		left outer join notificationsSent b on a.ukey = b.ukey_notification
			and a.userName = b.userName
			and a.emailAddress = b.emailAddress
		where b.ukey is null
			and isnull(a.subject, '') <> ''
			and isnull(a.message, '') <> ''
		order by a.emailAddress, a.ymd

	if @bIsPreview = 0
	begin

		-- rate limiter!

		if (select count(*) from #messagesToSend) > 500
		begin
			-- panic! email Cole, do not send these out

			set @cThisSubject = 'SQLBeat (' + @@servername + '): More than 500 messages are queued to send'
			set @cThisMessage = 'There are ' + convert(varchar(20), (select count(*) from #messagesToSend)) + ' messages in the hopper to send on ' + @@servername + '.'

			exec pr_sendMessage '', 'cole@sqlbeat.com', 'More than 100 messages are queued to send', @cThisMessage

		end
		else
		begin

			set @nUkeyMessage = 0

			while exists (select top 1 ukey from #messagesToSend where ukey > @nUkeyMessage and isnull(subject, '') <> '')
			begin
				select top 1
					@cThisSubject = 'SQLBeat (' + isnull(serverName, 'N/A') + ') : ' + isnull(subject, ''),
					@cThisMessage = message,
					@cEmailAddress = emailAddress,
					@nUkeyMessage = ukey
					from #messagesToSend
					where ukey > @nUkeyMessage
						and isnull(subject, '') <> ''
					order by ukey

	--			print replicate('=', 50)
	--			print @cThisSubject
	--			print @cThisMessage

				exec pr_sendMessage '', @cEmailAddress, @cThisSubject, @cThisMessage
			end

			insert into notificationsSent (ukey_notification, userName, emailAddress)
			select distinct ukey_notification, userName, emailAddress
				from #messagesToSend
		end
	end
	else
	begin
		select ukey, serverName, ymd, left(subject, 130) as subject, emailAddress
			from #messagesToSend
--			where ymd >= dateAdd(day, -1, getDate())
			order by ymd desc, subject
	end

	drop table #messages
	drop table #messagesToSend
end
