/****** Object:  StoredProcedure [dbo].[pr_dashboard_returnMessageRules]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from messageRules
-- update messageRules set severity = 0

-- exec pr_dashboard_returnMessageRules ''

CREATE procedure [dbo].[pr_dashboard_returnMessageRules] (@cUserName varchar(100) = '')
as
begin
	select ukey,
		userName, emailAddress, ruleType, whenToSend, serverList,
		case when right(ruleDescription, 2) in (', ', ': ') then left(ruleDescription, len(ruleDescription) - 1) else ruleDescription end as ruleDescription,
		case when right(sourceType, 2) = ', ' then left(sourceType, len(sourceType) - 1) else sourceType end as sourceType
		from (
			select
				c.userName,
				c.emailAddress,
				a.ukey,

				case when sendMessage = 1 then 'SEND'
					when doNotSendMessage = 1 then 'DO NOT SEND'
					else '' end as ruleType,

				case
					when isnull(businessHours, 0) = 1 and isnull(offHours, 0) = 1 then 'ALL'
					when isnull(businessHours, 0) = 1 and isnull(offHours, 0) = 0 then 'Business Hours, '
					when isnull(businessHours, 0) = 0 and isnull(offHours, 0) = 1 then 'Off Hours, '
					when isnull(businessHours, 0) = 0 and isnull(offHours, 0) = 0 then 'NEVER'
					else ''
					end as whenToSend,

				isnull(isnull(serverEquals, serverLike), 'ALL') + isnull(' ' + b.groupName, '') as serverList,

				isnull(subjectLike + ' : ', '') +
					isnull(messageLike + ' : ', '')
					as ruleDescription,

					case when isnull(isJobFailure, 0) = 1 then 'Job Failure, ' else '' end +
						case when isnull(isLongRunningJob, 0) = 1 then 'Long Running Job, ' else '' end +
						case when isnull(isBlocking, 0) = 1 then 'Blocking, ' else '' end +
						case when isnull(isLongRunningProcess, 0) = 1 then 'Long Running, ' else '' end +
						case when isnull(isDriveSpace, 0) = 1 then 'Drive Space, ' else '' end +
						case when isnull(isLogSize, 0) = 1 then 'Log Size, ' else '' end +
						case when isnull(isEventLog, 0) = 1 then 'Event Log, ' else '' end +
						case when isnull(isService, 0) = 1 then 'Service, ' else '' end +
						case when isnull(isConnectivity, 0) = 1 then 'Connectivity, ' else '' end +
						case when isnull(isConfiguration, 0) = 1 then 'Configuration, ' else '' end +
						case when isnull(isInstalledSoftware, 0) = 1 then 'Software, ' else '' end +
						case when isnull(isMonitorMessage, 0) = 1 then 'Monitoring, ' else '' end as sourceType
--					+ case when isnull(allMessages, 0) = 1 then 'All Messages, ' else '' end

				from messageRules a
				left outer join dm_serverGroups b on a.ukey_group = b.ukey
				left outer join userEmails c on a.ukey_userEmail = c.ukey
				where (a.userName = @cUserName or isnull(@cUserName, '') = '')
			) a
		order by userName,emailAddress,sourceType, ruleDescription
end
GO
