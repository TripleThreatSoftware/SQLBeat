	        ID="DataSource_Search"
	        SelectCommand="exec audit.dbo.pr_search @cServerName = @ServerName, @cDatabaseName = @DatabaseName, @cSearchString = @SearchString"

	        ID="DataSource_JobRuntimeHistory"
	        SelectCommand="exec pr_rpt_jobRuntimeHistory @cServerName = @ServerName, @nUkeyJob = @UkeyJob"




insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Server Summary', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Jobs', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Queries', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'Execution Stats', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'Observed', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'Blocking', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'CPU Load', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'Disk Load', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Waits', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Buffer Cache', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Performance', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Memory', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Databases', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Tables', 'SQL', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (14, 'Indexing', 'SQL', '', 'Heading')

delete from reportMetaData where ukey = 2

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Active Connections', 'SQL', 'pr_graph_connectionsByHour @cServerName, 800', 'Graph')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Page Life Expectancy', 'SQL', 'pr_graph_pageLifeExpectancy', 'Graph')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Detailed Load', 'SQL', 'pr_graph_sqlLoadByHour @cServerName, 800', 'ManyGraphs')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Average Load by Hour', 'SQL', 'pr_graph_sqlAverageHourlyLoad', 'Graph')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Drive Space History', 'SQL', 'pr_rpt_driveSpaceOverTime', 'Graph')

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Current Activity', 'SQL', 'pr_rpt_currentSQLActivity', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'SQL Errorlog', 'SQL', 'pr_rpt_sqlErrorLog 0, @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'OS EventLog', 'SQL', 'pr_rpt_eventLog 0, 24, @cServerName', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Alerts', 'SQL', 'pr_dashboard_returnAlerts @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Load by Database by Minute', 'SQL', 'pr_rpt_sqlLoadByDatabaseByMinute @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Job Summary', 'SQL', 'pr_rpt_jobSummary', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'Query Load', 'SQL', 'pr_rpt_querySummary @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'Recompiled Objects', 'SQL', 'pr_rpt_recompiledObjects @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'Remote Queries', 'SQL', 'pr_rpt_longRunningOLEDBQueries @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (3, 'Parallelism', 'SQL', 'pr_rpt_Parallelism', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (4, 'Summary', 'SQL', 'pr_rpt_executionStats', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (4, 'Longest Running', 'SQL', 'pr_rpt_executionStats_executionTime', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (4, 'Most IO', 'SQL', 'pr_rpt_executionStats_totalIO', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (5, 'Long Running', 'SQL', 'pr_rpt_longRunningQueries', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (5, 'Most Observed', 'SQL', 'pr_rpt_mostRunQueries @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (5, 'Run Times', 'SQL', 'pr_rpt_queryRuntimes', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (6, 'Blocked Queries', 'SQL', 'pr_rpt_blockedQueries @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (6, 'Blocking Queries', 'SQL', 'pr_rpt_blockingQueries @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (6, 'Blocking Event Detail', 'SQL', 'pr_rpt_sqlBlockingDetail @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (7, 'CPU Cycles', 'SQL', 'pr_rpt_cpuCycles @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (7, 'CPU Load by Hour', 'SQL', 'pr_rpt_heaviestLoadOverTime @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (8, 'Disk IO (Now)', 'SQL', 'pr_rpt_diskIO @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (8, 'Disk IO (48 hours)', 'SQL', 'pr_rpt_diskIOHistory @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (9, 'Process Waits', 'SQL', 'pr_rpt_waitTypesSummary', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (9, 'Server Waits', 'SQL', 'pr_rpt_serverWaits @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (9, 'CPU Waits', 'SQL', 'pr_rpt_sqlCPUWaits @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (9, 'Disk Waiting', 'SQL', 'pr_rpt_sqlDiskWaiting @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (9, 'Disk Waiting by Hour', 'SQL', 'pr_rpt_diskQueuesByHour', 'Graph')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (10, 'Current Contents', 'SQL', 'pr_rpt_bufferCacheContents @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (10, 'Current Contents (Pie)', 'SQL', 'pr_graph_bufferContents @cServerName, null, null', 'Graph')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (10, 'History (48 hours)', 'SQL', 'pr_rpt_bufferContents @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (10, 'Table Summary (48)', 'SQL', 'pr_rpt_bufferCache_tableWeek', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (10, 'Database Summary (48)', 'SQL', 'pr_rpt_bufferCache_databaseWeek', 'Table')

delete from reportMetaData where ukey = 11
update reportMetaData set storedProcedureName = 'pr_rpt_heaviestLoadOverTime @cServerName, 6' where reportName = 'CPU Load by Hour'

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Performance', 'SQL', 'pr_rpt_sqlStatistics', 'ManyGraphs')

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (12, 'Overview', 'SQL', 'pr_rpt_memoryStatistics', 'ManyGraphs')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (12, 'Allocation', 'SQL', 'pr_rpt_memoryAllocation @cServerName, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (12, 'Allocation History', 'SQL', 'pr_rpt_memoryAllocationGraph @cServerName, null, null', 'Graph')

update reportMetaData set reportType = 'Graph' where reportName = 'Allocation History'

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (13, 'Growth Summary', 'SQL', 'pr_rpt_databaseGrowthSummary', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (13, 'Growth Weekly Detail', 'SQL', 'pr_rpt_databaseGrowthDetail', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (13, 'Growth Event History', 'SQL', 'pr_rpt_databaseFileGrowthHistory @cServerName, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (13, 'Database Activity Summary', 'SQL', 'pr_rpt_databaseActivitySummary', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (13, 'Last User Activity', 'SQL', 'pr_rpt_databaseLastUserActivity', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (13, 'Database Size History', 'SQL', 'pr_rpt_databaseSizeOverTime', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (13, 'Most Recent Backup', 'SQL', 'pr_rpt_databaseLastBackup', 'Table')

update reportMetaData set reportType = 'Graph' where reportName = 'Database Size History'

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (14, 'Fragmentation', 'SQL', 'pr_rpt_fragmentation', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (14, 'Sizes', 'SQL', 'pr_rpt_tableSizes', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (15, '24 Hour Summary', 'SQL', 'pr_rpt_indexSummary @cServerName, 24', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (15, 'Week Summary', 'SQL', 'pr_rpt_indexSummary @cServerName, 168', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (15, 'Missing Indexes', 'SQL', 'pr_rpt_indexAnalysis_unindexed', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (15, 'Indexes Not Used', 'SQL', 'pr_rpt_indexAnalysis_notUsed', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (15, 'Bookmark Scans', 'SQL', 'pr_rpt_indexAnalysis_badClustered', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (15, 'Worst Performing', 'SQL', 'pr_rpt_worstPerformingTables @cServerName, 168', 'Table')







insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (null, 'Configuration', 'Server', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (88, 'Running Processes', 'Server', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (88, 'CPU', 'Server', '', 'Heading')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (88, 'Disk', 'Server', '', 'Heading')

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (88, 'Services Summary', 'Server', 'configuration.dbo.pr_rpt_serviceSummary @nUkeyServer', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (88, 'Installed Software', 'Server', 'installedSoftware..pr_rpt_installedSoftware @nUkeyServer', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (88, 'Event Log', 'Server', 'pr_rpt_eventLog @nUkeyServer, 24', 'Table')

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (89, 'Summary of Active', 'Server', 'configuration.dbo.pr_rpt_runningProcessSummary @nUkeyServer, null, null', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (89, 'Detail', 'Server', 'configuration.dbo.pr_rpt_runningProcessHistory @nUkeyServer, null, null', 'Table')

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (90, 'Data: By Week', 'Server', 'configuration.dbo.pr_rpt_cpuUtilization_weekly @nUkeyServer', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (90, 'Data: By Day', 'Server', 'configuration.dbo.pr_rpt_cpuUtilization_daily @nUkeyServer', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (90, 'Graph: Last 6 hours', 'Server', 'configuration.dbo.pr_graph_cpuUtilization @nUkeyServer, 6', 'Graph')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (90, 'Graph: Last Week', 'Server', 'configuration.dbo.pr_graph_cpuUtilization_byDay @nUkeyServer', 'Graph')

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (91, 'Queue Length: 48 Hours', 'Server', 'configuration.dbo.pr_graph_diskQueueLength @nUkeyServer, 48', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (91, 'Max Bytes per Second', 'Server', 'configuration.dbo.pr_graph_diskBytesPerSecond @nUkeyServer, 48', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (91, 'Disk Status', 'Server', 'configuration.dbo.pr_rpt_diskSummary @nUkeyServer', 'Table')

update reportMetaData set reportType = 'Graph' where reportName = 'Max Bytes per Second'
update reportMetaData set reportType = 'Graph' where reportName = 'Queue Length: 48 Hours'

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (91, 'Week Performance', 'Server', 'configuration.dbo.pr_rpt_diskPerformance @nUkeyServer, @cServerName', 'Table')


insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Drive Performance', 'SQL', '', 'Heading')

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (105, 'Overall', 'SQL', 'pr_rpt_drivePerformance @cServerName, 1', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (105, 'By Drive', 'SQL', 'pr_rpt_drivePerformance @cServerName, 2', 'Table')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (105, 'By Database', 'SQL', 'pr_rpt_drivePerformance @cServerName, 3', 'Table')


update reportMetaData set ukey_parent = 73 where ukey_parent = 88
update reportMetaData set ukey_parent = 74 where ukey_parent = 89
update reportMetaData set ukey_parent = 75 where ukey_parent = 90
update reportMetaData set ukey_parent = 76 where ukey_parent = 91

update reportMetaData set ukey_parent = 90 where ukey_parent = 105



select * from reportMetaData order by ukey desc
delete from reportMetaData where ukey in (66, 67, 68, 69)
update reportMetaData set reportType = 'Graph' where ukey = 59
