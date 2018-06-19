select top 1000 * from notification..notificationLog (nolock) order by ymd desc
select top 1000 * from notification..notificationLog_history (nolock) order by ymd desc

select top 1000 * from notification..notificationLog_history (nolock) where stepname like '%error:%' order by ymd desc

select * from weblogs.dbo.dm_sourceFiles where dateAdded >= dateadd(day, -1, getDate()) order by ukey desc

select
	convert(varchar(10), fileDate, 120),
	count(*) as numFiles,
	sum(convert(bigint, rowsLoaded)) as rowsLoaded,
	sum(convert(bigint, fileSize)) as fileSize,
	count(distinct webServerService + convert(varchar(2), datepart(hour, minYMD))) as serviceHours
	from weblogs.dbo.dm_sourceFiles (nolock)
	where fileDate >= '2018-03-01'
	group by convert(varchar(10), fileDate, 120)
	order by convert(varchar(10), fileDate, 120)
