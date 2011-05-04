create table dm_uriStem_archive (ukey int, uriStem varchar(8000), dateAdded dateTime, isPage bit)


select distinct ukey_uriStem
	into #usedURIs
	from mart_page_byday (nolock)
	where ymd >= dateAdd(month, -6, getDate())

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
