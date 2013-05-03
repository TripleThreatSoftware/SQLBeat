create index ix_useragentbyday_site_useragent_inc_ on mart_useragent_byday (ukey_site, ukey_useragent) include (uniques, requests) with fillfactor = 80
go
