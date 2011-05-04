drop index mart_page_byday.ix_martPageByDay_ymd_uriStem
go
create index ix_martPageByDay_ymd_uriStem on mart_page_byday (ymd, ukey_uriStem) with fillfactor = 80
