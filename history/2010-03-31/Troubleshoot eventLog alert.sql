update dm_servers set lastEventLogCheck = null where servername = 'appweb01'
delete from eventLog where computername = 'appweb01'
delete from eventLog_stage where computername = 'appweb01'
truncate table eventLog_history
truncate table eventLog
truncate table eventLog_stage

update dm_servers set eventLogCheck = 0

select * from dm_servers where servername = 'appweb01'
select top 500 * from eventLog where computername = 'appweb01' and sourceName like '%asp%' order by timeWritten desc
select top 500 * from eventLog_stage where computername = 'appweb01' and message not like '%security policies%' and sourceName not in ('W32Time', 'TermServDevices', 'Print') order by timeWritten desc
select top 500 * from eventLog_stage where computername = 'appweb01' and sourceName like '%asp%' order by timeWritten desc
select top 500 * from eventLog_stage where sourceName like '%asp%' order by timeWritten desc

select * from eventLog where sourceName like '%asp.net%'
select * from eventLog_stage where sourceName like '%asp.net%'

select * from eventLog_history order by ukey desc
select * from eventLog_history where servername = 'appweb01' order by ymd desc

select * from notificationLog where servername = 'appweb01' order by ymd desc

update dm_servers set eventLogCheck = 1, lastEventLogCheck = null where lastEventLogCheck >= dateAdd(week, -2, getDate()) or servername = 'appweb01'
