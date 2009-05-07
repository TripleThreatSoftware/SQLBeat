/****** Object:  StoredProcedure [dbo].[pr_dashboard_fulfillment]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_dashboard_fulfillment]
as
begin
	create table #results (groupName varchar(200), serverName varchar(200), messageBody varchar(8000))

	insert into #results (groupName, serverName, messageBody)
	select b.groupName, serverName,
			case
				when (eventLogCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastEventLogCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), eventLogCheckMinuteInterval) * 1.25)
					then 'Event Log check ' + convert(varchar(20), dateDiff(minute, isnull(lastEventLogCheck, dateAdd(day, -1, getDate())), getDate()) - eventLogCheckMinuteInterval) + ' minutes overdue. '
					else '' end +
			case
				when (detailedCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastDetailedCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), detailedCheckMinuteInterval) * 1.25)
					then 'Detailed SQL check ' + convert(varchar(20), dateDiff(minute, isnull(lastDetailedCheck, dateAdd(day, -1, getDate())), getDate()) - detailedCheckMinuteInterval) + ' minutes overdue. '
					else '' end +
			case
				when (serviceCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastServiceCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), serviceCheckMinuteInterval) * 1.25)
					then 'Services check ' + convert(varchar(20), dateDiff(minute, isnull(lastServiceCheck, dateAdd(day, -1, getDate())), getDate()) - serviceCheckMinuteInterval) + ' minutes overdue. '
					else '' end +
			case
				when (pingCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastPingCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), pingCheckMinuteInterval) * 1.25 and dateDiff(minute, lastPingCheck, getDate()) > 5)
					then 'PING check ' + convert(varchar(20), dateDiff(minute, isnull(lastPingCheck, dateAdd(day, -1, getDate())), getDate()) - pingCheckMinuteInterval) + ' minutes overdue. '
					else '' end +
			case
				when (integrityCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), integrityCheckMinuteInterval) * 1.25)
					then 'Integrity check ' + convert(varchar(20), dateDiff(minute, isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())), getDate()) - integrityCheckMinuteInterval) + ' minutes overdue. '
					else '' end +
			case
				when (configurationCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), configurationCheckMinuteInterval) * 1.50)
					then 'Configuration check ' + convert(varchar(20), dateDiff(minute, isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())), getDate()) - configurationCheckMinuteInterval) + ' minutes overdue. '
					else '' end +
			case
				when (fragmentationCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), fragmentationCheckMinuteInterval) * 1.25)
					then 'Fragmentation check ' + convert(varchar(20), dateDiff(minute, isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())), getDate()) - fragmentationCheckMinuteInterval) + ' minutes overdue. '
				else ''
				end

		from dm_servers a
		join dm_serverGroups b on a.ukey_group = b.ukey
		where isEnabled = 1
			and (
				(
					eventLogCheck = 1
					and convert(decimal(10,2),
						dateDiff(minute,
							case when isnull(eventLogCheckSleepUntil, '') > lastEventLogCheck then eventLogCheckSleepUntil
								else isnull(lastEventLogCheck, dateAdd(day, -1, getDate()))
								end, getDate()
							)
						) > convert(decimal(10,2), eventLogCheckMinuteInterval) * 1.25
					and dateDiff(minute, lastEventLogCheck, getDate()) > 5
					)
				or (
					detailedCheck = 1
					and convert(decimal(10,2),
						dateDiff(minute, isnull(lastDetailedCheck, dateAdd(day, -1, getDate())), getDate())
						) > convert(decimal(10,2), detailedCheckMinuteInterval) * 1.25
					and dateDiff(minute, lastDetailedCheck, getDate()) > 5
					)
				or (
					serviceCheck = 1
					and convert(decimal(10,2),
						dateDiff(minute, isnull(lastServiceCheck, dateAdd(day, -1, getDate())), getDate())
						) > convert(decimal(10,2), serviceCheckMinuteInterval) * 1.25
					and dateDiff(minute, lastServiceCheck, getDate()) > 5
					)
				or (
					pingCheck = 1
					and convert(decimal(10,2),
						dateDiff(minute, isnull(lastPingCheck, dateAdd(day, -1, getDate())), getDate())
						) > convert(decimal(10,2), pingCheckMinuteInterval) * 1.25
					and dateDiff(minute, lastPingCheck, getDate()) > 5
					)
				or (
					integrityCheck = 1
					and convert(decimal(10,2),
						dateDiff(minute, isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())), getDate())
						) > convert(decimal(10,2), integrityCheckMinuteInterval) * 1.25
					and dateDiff(minute, lastIntegrityCheck, getDate()) > 5
					)
				or (
					configurationCheck = 1
					and convert(decimal(10,2),
						dateDiff(minute, isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())), getDate())
						) > convert(decimal(10,2), configurationCheckMinuteInterval) * 1.50
					and dateDiff(minute, lastConfigurationCheck, getDate()) > 5
					)
				or (
					fragmentationCheck = 1
					and convert(decimal(10,2),
						dateDiff(minute, isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())), getDate())
						) > convert(decimal(10,2), fragmentationCheckMinuteInterval) * 1.25
					and dateDiff(minute, lastFragmentationCheck, getDate()) > 5
					)
				)
			and isServerPingable = 1

	insert into #results (groupName, serverName, messageBody)
	select 'Websites' as groupName,
		isnull(friendlyName, websiteURL) as serverName,
		'URL ' + isnull(friendlyName, websiteURL) + ' has not been checked for ' + convert(varchar(20), dateDiff(minute, isnull(lastCheck, '1980-08-28'), getDate())) + ' minutes.'
		from websiteMonitor..monitoredURLs
		where dateDiff(minute, isnull(lastCheck, dateAdd(week, -1, getDate())), getDate()) > 15
			and isEnabled = 1

	select *
		from #results
		order by groupName, serverName

	drop table #results
end
GO
