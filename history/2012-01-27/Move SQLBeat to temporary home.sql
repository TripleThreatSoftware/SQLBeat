exec pr_startAllJobs

select * from jobs order by jobName

exec pr_job_disable 276
exec pr_job_disable 22
exec pr_job_stop 22

update jobs set isEnabled = 0 where ukey in (40, 276, 22)

select top 100 * from jobHistory order by ymd desc

xp_readerrorlog

sp_configure 'Ole Automation Procedures', 1
reconfigure


ALTER DATABASE Scheduler SET TRUSTWORTHY ON, ENABLE_BROKER

select * from notification..dm_settings
