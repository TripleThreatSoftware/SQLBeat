create index ix_monitoredURLsHistory_ymd_message_url_isAvailable on monitoredURLs_history (ymd, message, ukey_url, isAvailable) with fillfactor = 70
create index ix_monitoredURLsHistory_message_ymd_url_isAvailable on monitoredURLs_history (message, ymd, ukey_url, isAvailable) with fillfactor = 70
create index ix_monitoredURLsHistory_ymd_url_isAvailable_message on monitoredURLs_history (ymd, ukey_url, isAvailable, message) with fillfactor = 70
create index ix_monitoredURLsHistory_ymd_url_isAvailable_message_ukey on monitoredURLs_history (ymd, ukey_url, isAvailable, message, ukey) with fillfactor = 70
create index ix_monitoredURLsHistory_ymd_message_url_isAvailable_ukey on monitoredURLs_history (ymd, message, ukey_url, isAvailable, ukey) with fillfactor = 70

create index ix_monitoredURLsHistory_url_ymd_isAvailable on monitoredURLs_history (ukey_url, ymd, isAvailable)
