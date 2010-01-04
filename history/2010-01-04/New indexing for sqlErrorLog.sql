create index ix_sqlErrorLog_ymd_logMessage_serverName_ukey on sqlErrorLog (ymd, logMessage, serverName, ukey) with fillfactor = 60
