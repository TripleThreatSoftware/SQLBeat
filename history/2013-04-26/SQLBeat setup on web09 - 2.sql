select top 100 * from scheduler.dbo.jobs order by jobName
select * from scheduler.dbo.jobSteps where ukey_job = 315 order by stepNumber
exec scheduler.dbo.pr_startAllJobs

update scheduler.dbo.jobSteps set stepText = 'exec pr_processSources' where ukey = 476
select top 100 * from scheduler.dbo.jobHistory where isError = 1 order by ymd desc

select top 100 * from notificationLog_history order by ymd desc
select top 100 * from eventLog_history order by ymd desc
select top 100 * from eventLog order by timewritten desc
select top 100 * from eventLog_stage order by timewritten desc

update dm_servers set lastEventLogCheck = dateAdd(hour, -24, getDate()) where servername <> 'web04'

select top 100 * from configuration.dbo.runs_data_stage
select top 100 * from configuration.dbo.runs_log order by ymd desc
sp_who2

select top 100 * from notificationLog order by ymd desc
select top 100 * from notificationLog where serverName = 'web09' order by ymd desc

select top 100 * from messagesSent order by ymd desc

select * from cdosysmail_failures

exec pr_sendAlerts '', 0, 0, 1

select top 100 * from eventLog where computerName = 'Web05' order by timewritten desc
select top 100 * from eventLog where computerName = 'Web06' order by timewritten desc
select top 100 * from eventLog where computerName = 'Web08' order by timewritten desc

select top 100 * from processLog where servername = 'web04' order by ymd, spid
select top 100 * from processLog where servername = 'web08' order by ymd, spid

xp_readerrorlog

sp_changedbowner 'sa'
