select * from dm_servers
select top 100 * from notificationLog_history where ukey_group = 1 order by ymd desc

select * from scheduler.dbo.jobs order by jobName
select * from scheduler.dbo.jobSteps where ukey_job = 275
select scheduler.dbo.fn_returnNextRuntime(84)
sp_helptext 'pr_monitorFreeAgent'
