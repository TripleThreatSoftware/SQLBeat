select top 100 * from notificationLog order by ymd desc
select top 100 * from processLog order by ymd desc

select top 100 * from messagesSent order by ymd desc
select top 100 * from cdosysmail_failures

update dm_servers set servername = 'web03-fast' where servername = 'web03'
select top 100 * from eventLog_history order by ymd desc

update dm_servers set lastEventLogCheck = '2012-05-01 17:00:00.000'

exec pr_readWindowsEvents 1

select top 100 * from eventLog order by monitorDate desc
select top 100 * from eventLog_stage order by timeWritten desc

select * from scheduler.. jobs order by jobName

exec scheduler.dbo.pr_job_disable 40

insert into messageRules (sendMessage, doNotSendMessage, messageLike) values (0, 1, 'the activated proc')
