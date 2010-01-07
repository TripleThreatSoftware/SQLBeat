create index ix_martPageByDay_site_ymd_uriStem_numRequests on mart_page_byday (ukey_site, ymd, ukey_uriStem) include (numRequests) with fillfactor = 70

create index ix_martPageByDay_uriStem_ymd_site on mart_page_byday (ukey_uriStem, ymd, ukey_site) include (pageLoadTime) with fillfactor = 70
