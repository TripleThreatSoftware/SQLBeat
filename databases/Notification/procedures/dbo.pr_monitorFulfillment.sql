SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_monitorFulfillment]
as
begin
	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @nNumRows int
	declare @bIsOffHours bit
	declare @nMinimumThreshold int

	if dbo.fn_isBusinessHours() = 1
	begin
		set @bIsOffHours = 0
		set @nMinimumThreshold = 10
	end
	else
	begin
		set @bIsOffHours = 1
		set @nMinimumThreshold = 15
	end

	create table #results (serverName varchar(200), messageBody varchar(8000))

	set @cThisMessage =
		left('Server' + space(20), 20) + ' ' +
		left('Details' + space(75), 75) + char(13) +

		replicate('=', 20) + ' ' +
		replicate('=', 75) + char(13)

	insert into #results (serverName, messageBody)
	select serverName,
			case
				when (eventLogCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastEventLogCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), eventLogCheckMinuteInterval) * 1.50)
					then 'Event Log check ' + convert(varchar(20), dateDiff(minute, isnull(lastEventLogCheck, dateAdd(day, -1, getDate())), getDate()) - eventLogCheckMinuteInterval) + ' minutes overdue. Last run was at ' + convert(varchar(20), lastEventLogCheck, 120) + '. '
					else '' end +
			case
				when (detailedCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastDetailedCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), detailedCheckMinuteInterval) * 1.50)
					then 'Detailed SQL check ' + convert(varchar(20), dateDiff(minute, isnull(lastDetailedCheck, dateAdd(day, -1, getDate())), getDate()) - detailedCheckMinuteInterval) + ' minutes overdue. Last run was at ' + convert(varchar(20), lastDetailedCheck, 120) + '. '
					else '' end +
			--case
			--	when (serviceCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastServiceCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), serviceCheckMinuteInterval) * 1.50)
			--		then 'Services check ' + convert(varchar(20), dateDiff(minute, isnull(lastServiceCheck, dateAdd(day, -1, getDate())), getDate()) - serviceCheckMinuteInterval) + ' minutes overdue. Last run was at ' + convert(varchar(20), lastServiceCheck, 120) + '. '
			--		else '' end +
			case
				when (pingCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastPingCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), pingCheckMinuteInterval) * 1.50 and dateDiff(minute, lastPingCheck, getDate()) > 5)
					then 'PING check ' + convert(varchar(20), dateDiff(minute, isnull(lastPingCheck, dateAdd(day, -1, getDate())), getDate()) - pingCheckMinuteInterval) + ' minutes overdue. Last run was at ' + convert(varchar(20), lastPingCheck, 120) + '. '
					else '' end
			--case
			--	when (integrityCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), integrityCheckMinuteInterval) * 1.50)
			--		then 'Integrity check ' + convert(varchar(20), dateDiff(minute, isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())), getDate()) - integrityCheckMinuteInterval) + ' minutes overdue. Last run was at ' + convert(varchar(20), lastIntegrityCheck, 120) + '. '
			--		else '' end +
			--case
			--	when (configurationCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), configurationCheckMinuteInterval) * 1.50)
			--		then 'Configuration check ' + convert(varchar(20), dateDiff(minute, isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())), getDate()) - configurationCheckMinuteInterval) + ' minutes overdue. Last run was at ' + convert(varchar(20), lastConfigurationCheck, 120) + '. '
			--		else '' end +
			--case
			--	when (fragmentationCheck = 1 and convert(decimal(10,2), dateDiff(minute, isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())), getDate())) > convert(decimal(10,2), fragmentationCheckMinuteInterval) * 1.50)
			--		then 'Fragmentation check ' + convert(varchar(20), dateDiff(minute, isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())), getDate()) - fragmentationCheckMinuteInterval) + ' minutes overdue. Last run was at ' + convert(varchar(20), lastFragmentationCheck, 120) + '. '
			--	else ''
			--	end

		from dm_servers (nolock)
		where isEnabled = 1
			and (
					(
						eventLogCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								case when isnull(eventLogCheckSleepUntil, '') > lastEventLogCheck
									then eventLogCheckSleepUntil
									else isnull(lastEventLogCheck, dateAdd(day, -1, getDate()))
									end, getDate()
								)
							) > convert(decimal(10,2), eventLogCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastEventLogCheck, getDate()) > (@nMinimumThreshold + eventLogCheckMinuteInterval)
						)
					or (
						detailedCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								isnull(lastDetailedCheck, dateAdd(day, -1, getDate())),
								getDate()
								)
							) > convert(decimal(10,2), detailedCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastDetailedCheck, getDate()) > (@nMinimumThreshold + detailedCheckMinuteInterval)
						)
					--or (
					--	serviceCheck = 1
					--	and convert(decimal(10,2),
					--		dateDiff(minute,
					--			isnull(lastServiceCheck, dateAdd(day, -1, getDate())),
					--			getDate()
					--			)
					--		) > convert(decimal(10,2), serviceCheckMinuteInterval) * 1.50
					--	and dateDiff(minute, lastServiceCheck, getDate()) > (@nMinimumThreshold + serviceCheckMinuteInterval)
					--	)
					or (
						pingCheck = 1
						and convert(decimal(10,2),
							dateDiff(minute,
								isnull(lastPingCheck, dateAdd(day, -1, getDate())),
								getDate()
								)
							) > convert(decimal(10,2), pingCheckMinuteInterval) * 1.50
						and dateDiff(minute, lastPingCheck, getDate()) > (@nMinimumThreshold + pingCheckMinuteInterval)
						)
					--or (
					--	integrityCheck = 1
					--	and convert(decimal(10,2),
					--		dateDiff(minute,
					--			isnull(lastIntegrityCheck, dateAdd(day, -1, getDate())),
					--			getDate()
					--			)
					--		) > convert(decimal(10,2), integrityCheckMinuteInterval) * 1.50
					--	and dateDiff(minute, lastIntegrityCheck, getDate()) > (@nMinimumThreshold + integrityCheckMinuteInterval)
					--	and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
					--	and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
					--	)
					--or (
					--	configurationCheck = 1
					--	and convert(decimal(10,2),
					--		dateDiff(minute,
					--			isnull(lastConfigurationCheck, dateAdd(day, -1, getDate())),
					--			getDate()
					--			)
					--		) > convert(decimal(10,2), configurationCheckMinuteInterval) * 3
					--	and dateDiff(minute, lastConfigurationCheck, getDate()) > (@nMinimumThreshold + configurationCheckMinuteInterval)
					--	)
					--or (
					--	fragmentationCheck = 1
					--	and convert(decimal(10,2),
					--		dateDiff(minute,
					--			isnull(lastFragmentationCheck, dateAdd(day, -1, getDate())),
					--			getDate()
					--			)
					--		) > convert(decimal(10,2), fragmentationCheckMinuteInterval) * 1.50
					--	and dateDiff(minute, lastFragmentationCheck, getDate()) > (@nMinimumThreshold + fragmentationCheckMinuteInterval)
					--	and right(convert(varchar(20), getDate(), 120), 8) >= right(convert(varchar(20), maintenanceWindowStart, 120), 8)
					--	and right(convert(varchar(20), getDate(), 120), 8) <= right(convert(varchar(20), maintenanceWindowStop, 120), 8)
					--	)
					)
			and isServerPingable = 1

	if exists (select top 1 [name] from master..sysdatabases where [name] = 'websiteMonitor')
	begin
		insert into #results (serverName, messageBody)
		select isnull(friendlyName, websiteURL) as serverName,
			'URL ' + isnull(friendlyName, websiteURL) + ' has not been checked for ' + convert(varchar(20), dateDiff(minute, isnull(lastCheck, '1980-08-28'), getDate())) + ' minutes.'
			from websiteMonitor..monitoredURLs
			where dateDiff(minute, isnull(lastCheck, dateAdd(week, -1, getDate())), getDate()) > 15
				and isEnabled = 1
	end

	-- if we sent an alert in the last 10 minutes, don't send another for a little bit
	delete #results
		from #results a
		join notificationLog b (nolock) on a.serverName = b.serverName
			and b.subject like '%fulfillment failure%'
			and b.ymd >= dateAdd(minute, -10, getDate())

	insert into notificationLog_stage (serverName, subject, message, severity)
	select serverName, 'Fulfillment failure at ' + convert(varchar(20), getDate(), 120), messageBody, 1 as severity
		from #results

	drop table #results
end
