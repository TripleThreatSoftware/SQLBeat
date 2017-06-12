---- xp_fixeddrives
-- sp_who2
-- dbcc inputbuffer(64)
--select top 100 * from fact_weblogs_stage_hist (nolock) where stepname like '%W3SVC42\u_ex17060617.log%' order by ymd desc

-- select count(*) from fact_weblogs_Stage
select top 10000 * from fact_weblogs_stage_hist (nolock) order by ymd desc
select top 100 * from fact_weblogs_stage_hist (nolock) where stepname like '%error%' order by ymd desc
select top 100 * from hist_partitionTableDaily (nolock) where stepname like '%error%' order by ymd desc

--select top 100 * from fact_weblogs_stage_hist (nolock) where ukey between 15500874 - 25 and 15500883 + 25 order by ymd desc

--select top 100 * from dm_sourcefiles order by dateadded desc
--select * from dm_sourcefiles where ukey_site = 95 order by sourcefile desc

--update dm_sourceFiles set errors = null where minYMD is null and fileDate >= '2017-06-01' and errors is not null

--\\web01\inetpub\logs\LogFiles\W3SVC42\u_ex17060617.log
--\\web01\inetpub\logs\LogFiles\W3SVC42\u_ex17052500.log
--\\web01\inetpub\logs\LogFiles\W3SVC42\u_ex17060411.log
--\\web01\inetpub\logs\LogFiles\W3SVC42\u_ex17053111.log
--truncate table fact_weblogs_stage_coletest

-- select top 0 * into fact_weblogs_stage_coletest from fact_weblogs_stage


			--bulk insert fact_weblogs_stage_coletest
			--	from '\\web01\inetpub\logs\LogFiles\W3SVC42\u_ex17053111.log'
			--	WITH
			--	(
			--		FIRSTROW = 5,
			--		FIELDTERMINATOR =' ',
			--		ROWTERMINATOR ='\n',
			--		MAXERRORS = 1000,
			--		FORMATFILE = 'c:\temp\import_cole.fmt'
			--	)
--==================================================
--Output from call:

--Starting copy...

--24 rows copied.
--Network packet size (bytes): 4096
--Clock Time (ms.) Total     : 1      Average : (24000.00 rows per sec.)
