USE [Weblogs]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- create table dm_uriStem_archive (ukey int, uriStem varchar(8000), dateAdded dateTime, isPage bit)
--create table mart_page_byday_archive (ukey int, ukey_site int, ukey_uristem int, requestStatus int, ymd dateTime, numRequests int, numRequests_human int,
--	uniques int, uniques_human int, pageLoadTime int, pagePostTime int, getTime int, postTime int)

-- select max(ymd) from weblogs_archive.dbo.mart_page_byday_archive

ALTER procedure [dbo].[pr_archiveOldData]
as
begin
	if not exists (select top 1 name from weblogs_archive.dbo.sysfiles where name = 'mart_page_byday_archive')
	begin
		select top 0 convert(bigint, ukey) as ukey, ukey_site, ukey_uristem, requestStatus, ymd, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime
			into weblogs_archive.dbo.mart_page_byday_archive
			from mart_page_byday (nolock)
	end

	if not exists (select top 1 name from weblogs_archive.dbo.sysfiles where name = 'mart_page_byhour_archive')
	begin
		select top 0 convert(bigint, ukey) as ukey, ukey_site, ukey_uriStem, requestStatus, ymd, hour, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime
			into weblogs_archive.dbo.mart_page_byhour_archive
			from mart_page_byhour (nolock)
	end

	if not exists (select top 1 name from weblogs_archive.dbo.sysfiles where name = 'dm_uriStem_archive')
	begin
		select top 0 convert(bigint, ukey) as ukey, uriStem, dateAdded, isPage
			into weblogs_archive.dbo.dm_uriStem_archive
			from dm_uriStem (nolock)
	end

	--************************************************************************************************************************************************************************************************

	insert into weblogs_archive.dbo.mart_page_byday_archive (ukey, ukey_site, ukey_uristem, requestStatus, ymd, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime)
	select ukey, ukey_site, ukey_uristem, requestStatus, ymd, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime
		from mart_page_byday (nolock)
		where ymd < dateAdd(month, -3, getDate())

	delete from mart_page_byday with (tablock) where ymd < dateAdd(month, -3, getDate())

	insert into weblogs_archive.dbo.mart_page_byhour_archive (ukey, ukey_site, ukey_uriStem, requestStatus, ymd, hour, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime)
	select ukey, ukey_site, ukey_uriStem, requestStatus, ymd, hour, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime
		from mart_page_byhour (nolock)
		where ymd < dateAdd(month, -2, getDate())

	delete from mart_page_byhour with (tablock) where ymd < dateAdd(month, -2, getDate())

	select distinct ukey_uriStem
		into #usedURIs
		from v_fact_weblogs_all (nolock)

	create clustered index ix_tmp_usedURIs on #usedURIs (ukey_uriStem) with fillfactor = 100

	insert into weblogs_archive.dbo.dm_uriStem_archive (ukey, uriStem, dateAdded, isPage)
	select a.ukey, a.uriStem, a.dateAdded, a.isPage
		from dm_uriStem a (nolock)
		left outer join #usedURIs b on a.ukey = b.ukey_uriStem
		left outer join weblogs_archive.dbo.dm_uriStem_archive c on a.ukey = c.ukey
		where b.ukey_uriStem is null
			and c.ukey is null

	delete dm_uriStem with (tablock)
		from dm_uriStem a
		left outer join #usedURIs b on a.ukey = b.ukey_uriStem
		where b.ukey_uriStem is null

	drop table #usedURIs
end

--select * from scheduler.dbo.jobs order by jobname
--select * from scheduler.dbo.jobHistory where ukey_job = 276 order by ukey
