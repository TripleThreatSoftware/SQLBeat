/****** Object:  StoredProcedure [dbo].[pr_dashboard_monitorStatistics]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_dashboard_monitorStatistics]
as
begin
	declare @results table (ukey int identity, keyName varchar(100), keyValue int, hyperlink varchar(200))

	insert into @results (keyName, keyValue, hyperlink)
	select 'Servers Monitored' as keyName, count(*) as keyValue, 'configureServers.aspx' from dm_servers where isEnabled = 1

	insert into @results (keyName, keyValue)
	select 'Websites Monitored' as keyName, count(*) as keyValue from websiteMonitor..monitoredURLs where isEnabled = 1

	insert into @results (keyName, keyValue)
	select 'Servers Down' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and isServerPingable = 0

	insert into @results (keyName, keyValue)
	select 'PING Checked' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and pingCheck = 1

	insert into @results (keyName, keyValue)
	select 'EventLog Checked' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and eventLogCheck = 1

	insert into @results (keyName, keyValue)
	select 'Installed Software Checked' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and installedSoftwareCheck = 1

	insert into @results (keyName, keyValue)
	select 'Configuration Checked' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and configurationCheck = 1

	insert into @results (keyName, keyValue)
	select 'Servers Sleeping' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and isnull(eventLogCheckSleepUntil, '') > getDate()

	insert into @results (keyName, keyValue)
	select 'SQL Instances' as keyName, count(*) as keyValue from dm_servers where isEnabled = 1 and isSQLBox = 1

	insert into @results (keyName, keyValue)
	select 'Alerts (Last Hour)' as keyName, count(*) as keyValue from notificationLog where ymd >= dateAdd(hour, -1, getDate())

	insert into @results (keyName, keyValue)
	select 'Alerts (Last 24 Hours)' as keyName, count(*) as keyValue from notificationLog where ymd >= dateAdd(hour, -24, getDate())

	select * from @results order by ukey
end

--unionselect * from dm_servers
GO
