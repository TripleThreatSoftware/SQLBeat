select top 100 * from tmp_AppDb_pageData order by ymd desc
select top 100 * from dm_sourceFiles where webserver = 'web01' order by fileDate desc



select ymd, count(*) from tmp_AppDb_pageData group by ymd order by ymd desc

select * From dm_sourceFiles where fileDate between '2018-10-14 00:00:00.000' and '2018-10-18 00:00:00.000'

select * from dm_sources where isEnabled = 1

create table #folders (folderName varchar(100))

insert into #folders
exec master..xp_cmdshell 'dir /b \\web02\inetpub\logs\logfiles'

insert into dm_sources (sourcePath, isApache, isIIS, readHeader, checkMinuteInterval, isEnabled, monthsBackToLook)
select '\\web02\inetpub\logs\logfiles\' + a.folderName, 0, 1, 1, 60, 1, 3
	from #folders a
	left outer join dm_sources b on b.sourcePath = '\\web02\inetpub\logs\logfiles\' + a.folderName
	where a.folderName like 'W3%'
		and b.ukey is null

truncate table #folders

insert into #folders
exec master..xp_cmdshell 'dir /b \\web01\inetpub\logs\logfiles'

insert into dm_sources (sourcePath, isApache, isIIS, readHeader, checkMinuteInterval, isEnabled, monthsBackToLook)
select '\\web01\inetpub\logs\logfiles\' + a.folderName, 0, 1, 1, 60, 1, 3
	from #folders a
	left outer join dm_sources b on b.sourcePath = '\\web01\inetpub\logs\logfiles\' + a.folderName
	where a.folderName like 'W3%'
		and b.ukey is null
