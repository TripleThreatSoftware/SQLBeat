-- create table dm_uriStem_archive (ukey int, uriStem varchar(8000), dateAdded dateTime, isPage bit)
--create table mart_page_byday_archive (ukey int, ukey_site int, ukey_uristem int, requestStatus int, ymd dateTime, numRequests int, numRequests_human int,
--	uniques int, uniques_human int, pageLoadTime int, pagePostTime int, getTime int, postTime int)

create procedure pr_archiveOldData
as
begin

	insert into mart_page_byday_archive (ukey, ukey_site, ukey_uristem, requestStatus, ymd, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime)
	select ukey, ukey_site, ukey_uristem, requestStatus, ymd, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime
		from mart_page_byday (nolock)
		where ymd < dateAdd(month, -3, getDate())

	delete from mart_page_byday with (tablock) where ymd < dateAdd(month, -3, getDate())

	select distinct ukey_uriStem
		into #usedURIs
		from mart_page_byday (nolock)

	create clustered index ix_tmp_usedURIs on #usedURIs (ukey_uriStem) with fillfactor = 100

	insert into dm_uriStem_archive (ukey, uriStem, dateAdded, isPage)
	select a.ukey, a.uriStem, a.dateAdded, a.isPage
		from dm_uriStem a (nolock)
		left outer join #usedURIs b on a.ukey = b.ukey_uriStem
		where b.ukey_uriStem is null

	delete dm_uriStem with (tablock)
		from dm_uriStem a
		left outer join #usedURIs b on a.ukey = b.ukey_uriStem
		where b.ukey_uriStem is null

	drop table #usedURIs
end
