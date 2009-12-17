drop index dm_userAgent.ix_dm_userAgent
go
create index ix_dmUserAgent_ukey_browser_service_os_userAgent on dm_userAgent (ukey) include (browserName, serviceName, osName, userAgent) with fillfactor = 80
go
create index ix_dmUserAgent_ukey_browser_isHuman on dm_userAgent (ukey, browserName, isHuman) with fillfactor = 80
go
