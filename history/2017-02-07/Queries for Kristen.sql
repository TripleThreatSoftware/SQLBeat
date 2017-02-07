select top 100 * from notification.dbo.eventlog (nolock) where computername = 'web01' and sourcename like '%asp.net%' order by timeWritten desc
select top 100 a.*
	from configuration.dbo.processorLoadLog a (nolock)
	join notification.dbo.dm_servers b (nolock) on a.ukey_server = b.ukey
	where servername in ('web01', 'web02')
	order by a.ymd desc

select * from configuration.dbo.applicationPoolLog (nolock) order by ymd desc
select top 100 * from notification.dbo.servicelog
