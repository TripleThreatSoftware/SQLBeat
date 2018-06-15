select top 1000 * from notification..notificationLog where isEventLog = 0 order by ymd desc
select top 10000 * from notificationLog_history order by ymd desc
select servername, serverVersion, cpuQueueThreshold from dm_Servers where isEnabled = 1 order by servername
select top 100 * from notification..drivespaceLog order by ymd desc
select top 100 * from weblogs.dbo.fact_weblogs_stage_hist order by ymd desc

select top 10000 * from weblogs.dbo.fact_weblogs_stage_hist where stepname like '%error%' order by ymd desc

select top 1000 * from notification..notificationLog where message like '%denied%' order by ymd desc

select * from notification..dm_settings

update notification..dm_settings set settingValue = 'd:\sqldata\' where ukey = 18
update notification..dm_settings set settingValue = 'd:\sqllog\' where ukey = 19
update notification..dm_settings set settingValue = 'spmonitoring01' where ukey = 3

exec master..xp_cmdshell 'whoami'
exec master..xp_cmdshell 'dir \\web02\inetpub'

select * from messagesSent where ymd >= '2018-06-15' and subject like '%status%'
select top 1000 * from notification..notificationLog where subject like '%status%' order by ymd desc
select * from messageRules

update messagerules set ukey_group = 1 where ukey = 3

select * from dm_serverGroups
