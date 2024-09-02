-- confirm which user account SQL will shell out as
exec master..xp_cmdshell 'whoami'

-- create a C:\TEMP folder

-- share your weblogs folder on your webserver
-- screenshot

-- confirm that this account can view your log folder
exec master..xp_cmdshell 'dir \\web02\iis_logfiles'

-- if you have to modify permissions at the source, you may need to restart SQL Services to see those changes reflected in actual access rights

-- if you want config file monitoring to work, you need your SQL Service account to be an admin on your webserver boxes - it will use C$ shares

-- add sources
use weblogs
go

truncate table fact_weblogs
truncate table fact_weblogs_stage
truncate table dm_sourceFiles
truncate table fact_weblogs_stage_hist

--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************


insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc1', 0, 1, 1, 1)
insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc2', 0, 1, 1, 1)
insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc3', 0, 1, 1, 1)
insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc4', 0, 1, 1, 1)
insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc5', 0, 1, 1, 1)
insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc6', 0, 1, 1, 1)
insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc7', 0, 1, 1, 1)
insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc8', 0, 1, 1, 1)
insert into dm_sources (sourcePath, isApache, isIIS, readHeader, isEnabled) values ('\\web02\iis_logfiles\w3svc9', 0, 1, 1, 1)

select * from dm_sources

--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************


-- an ARCHIVE job is available, but disabled, to periodically tail-off old data to an ARCHIVE database
"Archive Weblog MART data"

-- create an instance of "IIS Monitor" job for each monitored IIS server
"IIS Monitor"

-- create an instance of "Import Weblogs" job for each monitored IIS server
"Import Weblogs"

-- within the HOURLY job, create a step to scan for new log folders for each monitored IIS server
"Import Weblogs - Hourly"

-- enable PS1 script running (as admin)
PS > Set-ExecutionPolicy -ExecutionPolicy Unrestricted


--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************

-- check logs for errors
select * from fact_weblogs_stage_hist
select * from fact_errorLogs_stage_hist

-- confirm that all data is being recorded
select * from dm_sourceFiles order by fileDate desc

select c.clientIP, b.uriStem, a.*
	from v_fact_weblogs_all a
	left outer join dm_uristem b on a.ukey_uristem = b.ukey
	join dm_clientIP c on a.ukey_clientIP = c.ukey
	where ymd >= dateadd(day, -1, getDate())
		and not uriStem in ('/', '/favico.ico')
	order by ymd desc



select * from mart_site_byday order by ymd desc			-- GOOD
select * from mart_site_page_byday order by ymd desc	-- GOOD
select * from mart_useragent_byday order by ymd desc	-- GOOD

select b.uriStem, a.*
	from mart_page_byday a
	left outer join dm_uristem b on a.ukey_uristem = b.ukey
	order by a.ymd desc

select * from dm_sites where ukey in (2,3)

select * from configuration.dbo.iisSnapshot
select * from configuration.dbo.applicationPoolLog
select * from audit.dbo.auditData_config



--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************

select a.*, b.uriStem, c.userAgent, d.clientIP
	from v_fact_weblogs_all a
	join dm_uristem b on a.ukey_uristem = b.ukey
	join dm_useragent c on a.ukey_useragent = c.ukey
		and not c.useragent like '%hetrix%'
		and not c.useragent like '%googlebot%'
		and not c.useragent like '%yandexbot%'
	join dm_clientip d on a.ukey_clientip = d.ukey
	where a.ymd >= dateadd(week, -1, getDate())
		and not clientIP in ('73.237.69.56', '127.0.0.1') -- home
		and not uriStem in ('/favicon.ico', '/robots.txt', '/sql-server-database-monitoring/sql-monitoring.aspx', '/user-defined-alerts-and-dashboards.aspx', '/sql-monitoring.aspx')
		and not requestStatus in ('200', '301')
	order by a.ymd desc

-- block these IPs
select clientIP, userAgent, count(*)
	from v_fact_weblogs_all a
	join dm_uristem b on a.ukey_uristem = b.ukey
	join dm_useragent c on a.ukey_useragent = c.ukey
		and not c.useragent like '%hetrix%'
		and not c.useragent like '%googlebot%'
		and not c.useragent like '%yandexbot%'
	join dm_clientip d on a.ukey_clientip = d.ukey
	where a.ymd >= dateadd(week, -1, getDate())
		and not clientIP in ('73.237.69.56', '127.0.0.1') -- home
		and not uriStem in ('/favicon.ico', '/robots.txt', '/sql-server-database-monitoring/sql-monitoring.aspx', '/user-defined-alerts-and-dashboards.aspx', '/sql-monitoring.aspx')
		and not requestStatus in ('200', '301')
	group by clientIP, userAgent
	having count(*) >= 20 or sum(case when uriStem like '%php%' then 1 else 0 end) > 0
	order by clientIP, userAgent
