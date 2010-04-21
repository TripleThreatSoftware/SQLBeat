--select * from serverSelection

create table dashboardBlocks (ukey int identity, ymd dateTime default getDate(), machineID varchar(100), dashboard varchar(100),
	sortOrder int default 0, blockTitle varchar(200), blockSummary varchar(500), blockData varchar(500))
go

truncate table dashboardBlocks
go

insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 1, 'Connectivity', 'pr_rpt_blockSummary_connectivity', 'pr_rpt_blockData_connectivity')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 2, 'Processor', 'pr_rpt_blockSummary_processor', 'pr_rpt_blockData_processor')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 3, 'Disk Space', 'pr_rpt_blockSummary_disk', 'pr_rpt_blockData_disk')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 4, 'SQL Server Performance', 'pr_rpt_blockSummary_sql', 'pr_rpt_blockData_sql')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 5, 'IIS', 'pr_rpt_blockSummary_iis', 'pr_rpt_blockData_iis')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 6, 'Websites', 'pr_rpt_blockSummary_websites', 'pr_rpt_blockData_websites')

insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 7, 'Disk Performance', 'pr_rpt_blockSummary_diskPerformance', 'pr_rpt_blockData_diskPerformance')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 8, 'SQL Server Jobs', 'pr_rpt_blockSummary_sqlJobs', 'pr_rpt_blockData_sqlJobs')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 9, 'Outages', 'pr_rpt_blockSummary_outages', 'pr_rpt_blockData_outages')

insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'0nqmeb55ag5ygnfahetepd45', 'Home', 10, 'SQL Server Delays', 'pr_rpt_blockSummary_sqlDelays', 'pr_rpt_blockData_sqlDelays')

go



insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 1, 'Connectivity', 'pr_rpt_blockSummary_connectivity', 'pr_rpt_blockData_connectivity')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 2, 'Processor', 'pr_rpt_blockSummary_processor', 'pr_rpt_blockData_processor')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 3, 'Disk Space', 'pr_rpt_blockSummary_disk', 'pr_rpt_blockData_disk')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 4, 'SQL Server Performance', 'pr_rpt_blockSummary_sql', 'pr_rpt_blockData_sql')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 5, 'IIS', 'pr_rpt_blockSummary_iis', 'pr_rpt_blockData_iis')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 6, 'Websites', 'pr_rpt_blockSummary_websites', 'pr_rpt_blockData_websites')

insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 7, 'Disk Performance', 'pr_rpt_blockSummary_diskPerformance', 'pr_rpt_blockData_diskPerformance')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 8, 'SQL Server Jobs', 'pr_rpt_blockSummary_sqlJobs', 'pr_rpt_blockData_sqlJobs')
insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 9, 'Outages', 'pr_rpt_blockSummary_outages', 'pr_rpt_blockData_outages')

insert into dashboardBlocks (machineID, dashboard, sortOrder, blockTitle, blockSummary, blockData) values (
	'l32t3j45ljq30l450aztva45', 'Home', 10, 'SQL Server Delays', 'pr_rpt_blockSummary_sqlDelays', 'pr_rpt_blockData_sqlDelays')

go
