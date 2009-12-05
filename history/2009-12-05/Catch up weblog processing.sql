truncate table dm_sources
truncate table dm_sourceFiles
truncate table fact_weblogs
truncate table dm_sites
truncate table fact_weblogs_stage
truncate table fact_weblogs_preview

insert into dm_sources (sourcePath, isApache, isIIS, readHeader, checkMinuteInterval, isEnabled, monthsBackToLook) values (
	'\\192.168.1.14\logfiles\W3SVC13\', 0, 1, 1, 60, 1, 12)

exec pr_processSources
select * from dm_sources
select * from dm_sourceFiles
update dm_sources set lastCheck = null
pr_maintainPartitionedViews
--select * from dm_sourceFiles
