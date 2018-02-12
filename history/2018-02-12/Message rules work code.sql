declare @cUserName varchar(100)
declare @bIsBusinessHours bit
set @bIsBusinessHours= 1

	select
		b.ukey as ukey_rule, b.userName, c.emailAddress, a.*
		from notificationLog a (nolock)
		left outer join messageRules b (nolock) on
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
				or isnull(businessHours, 0) = 0
				)
			and (b.userName = @cUserName or isnull(@cUserName, '') = '')
		join userEmails c (nolock) on b.ukey_userEmail = c.ukey
		left outer join dm_servers d (nolock) on a.serverName = d.serverName
		where (
				b.ukey_group = d.ukey_group
				or isnull(b.ukey_group, 0) = 0
--				or isnull(d.ukey_group, 0) = 0
				)
			and (a.ymd >= dateAdd(hour, -72, getdate()) )

			and a.subject like '%malicious user%'
