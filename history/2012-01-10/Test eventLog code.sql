update dm_servers set lastEventLogCheck = null where serverName = 'web05'
delete from eventLog where computerName = 'web05'
go
exec pr_readWindowsEvents 1
go
exec pr_processEventLogMessages 1
go
select top 100 * from eventLog_history where ukey_group = 1 order by ymd desc
select * from eventLog_stage where computerName = 'web05' order by timeWritten desc
select top 100 * from eventLog where computerName = 'web05' order by timeWritten desc

select top 100 * from notificationLog where serverName = 'web05' order by ymd desc

select lastEventLogCheck from dm_servers where serverName = 'web05'
