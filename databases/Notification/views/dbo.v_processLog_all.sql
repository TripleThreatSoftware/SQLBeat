create view v_processLog_all as
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200809..processLog_20080917  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200809..processLog_20080916  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200809..processLog_20080915  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200809..processLog_20080911  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200809..processLog_20080908  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200809..processLog_200809_week36  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200807..processLog_200807_week31  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200807..processLog_200807_week29  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200807..processLog_200807_week27  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200806..processLog_200806_week27  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200806..processLog_200806_week26  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200806..processLog_200806_week24  union all
	select blockedBy,buffercontents,command,cputime,dbName,diskio,hostname,isBlocked,isBlocker,isWild,lastBatch,lastBatchTime,lastWaitType,locks,login,login_time,net_address,programName,serverName,spid,sql_handle,status,ukey,waitResource,waitTime,waitType,ymd
	from Notification200806..processLog_200806_week23
GO
Tables
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
name	xtype	name	length	xprec	type	xtype	isnullable
cdosysmail_failures	U 	Body	8000	0	39	167	1
cdosysmail_failures	U 	Comment about Failure	50	0	39	167	1
cdosysmail_failures	U 	Date of Failure	8	23	111	61	1
cdosysmail_failures	U 	Description of Failure	500	0	39	167	1
cdosysmail_failures	U 	From	100	0	39	167	1
cdosysmail_failures	U 	Hr	4	10	38	56	1
cdosysmail_failures	U 	iMsg	4	10	38	56	1
cdosysmail_failures	U 	Output from Failure	1000	0	39	167	1
cdosysmail_failures	U 	Source of Failure	255	0	39	167	1
cdosysmail_failures	U 	Spid	4	10	38	56	1
cdosysmail_failures	U 	Subject	100	0	39	167	1
cdosysmail_failures	U 	To	100	0	39	167	1
databaseFileSizeLog	U 	dbname	100	0	39	167	1
databaseFileSizeLog	U 	fileName	100	0	39	167	1
databaseFileSizeLog	U 	isLog	1	1	50	104	1
databaseFileSizeLog	U 	objectname	100	0	39	167	1
databaseFileSizeLog	U 	serverName	200	0	39	167	1
databaseFileSizeLog	U 	size	8	19	108	127	1
databaseFileSizeLog	U 	ukey	4	10	56	56	0
databaseFileSizeLog	U 	ymd	8	23	111	61	1
databaseFileSizeLog_stage	U 	dbname	100	0	39	167	1
databaseFileSizeLog_stage	U 	fileName	100	0	39	167	1
databaseFileSizeLog_stage	U 	isLog	1	1	50	104	1
databaseFileSizeLog_stage	U 	objectname	100	0	39	167	1
databaseFileSizeLog_stage	U 	serverName	200	0	39	167	1
databaseFileSizeLog_stage	U 	size	8	19	108	127	1
databaseFileSizeLog_stage	U 	ukey	4	10	56	56	0
databaseFileSizeLog_stage	U 	ymd	8	23	111	61	1
deepSQLStats	U 	keyName	100	0	39	167	1
deepSQLStats	U 	keyValue	8000	0	39	167	1
deepSQLStats	U 	serverName	100	0	39	167	1
deepSQLStats	U 	subkeyName	100	0	39	167	1
deepSQLStats	U 	ukey	4	10	56	56	0
deepSQLStats	U 	ukey_server	4	10	38	56	1
deepSQLStats	U 	ymd	8	23	111	61	1
deepSQLStats_bufferCache	U 	buffers	8	19	108	127	1
deepSQLStats_bufferCache	U 	databaseName	200	0	39	167	1
deepSQLStats_bufferCache	U 	indexNumber	4	10	38	56	1
deepSQLStats_bufferCache	U 	serverName	100	0	39	167	1
deepSQLStats_bufferCache	U 	tableName	500	0	39	167	1
deepSQLStats_bufferCache	U 	ukey	4	10	56	56	0
deepSQLStats_bufferCache	U 	ukey_server	4	10	38	56	1
deepSQLStats_bufferCache	U 	ymd	8	23	111	61	1
deepSQLStats_cpuConsumers	U 	bufferContents	8000	0	39	167	1
deepSQLStats_cpuConsumers	U 	numCPUSeconds	8	19	108	127	1
deepSQLStats_cpuConsumers	U 	numExecutions	8	19	108	127	1
deepSQLStats_cpuConsumers	U 	numMinutes	8	19	108	127	1
deepSQLStats_cpuConsumers	U 	readingType	100	0	39	167	1
deepSQLStats_cpuConsumers	U 	serverName	100	0	39	167	1
deepSQLStats_cpuConsumers	U 	ukey	4	10	56	56	0
deepSQLStats_cpuConsumers	U 	ukey_server	4	10	38	56	1
deepSQLStats_cpuConsumers	U 	ymd	8	23	111	61	1
deepSQLStats_cpuTasks	U 	cpuNumber	4	10	38	56	1
deepSQLStats_cpuTasks	U 	numTasks	4	10	38	56	1
deepSQLStats_cpuTasks	U 	numTasksWaiting	4	10	38	56	1
deepSQLStats_cpuTasks	U 	serverName	100	0	39	167	1
deepSQLStats_cpuTasks	U 	ukey	4	10	56	56	0
deepSQLStats_cpuTasks	U 	ukey_server	4	10	38	56	1
deepSQLStats_cpuTasks	U 	ymd	8	23	111	61	1
deepSQLStats_diskIOConsumers	U 	bufferContents	8000	0	39	167	1
deepSQLStats_diskIOConsumers	U 	diskIOUnits	8	19	108	127	1
deepSQLStats_diskIOConsumers	U 	numExecutions	8	19	108	127	1
deepSQLStats_diskIOConsumers	U 	numMinutes	8	19	108	127	1
deepSQLStats_diskIOConsumers	U 	readingType	100	0	39	167	1
deepSQLStats_diskIOConsumers	U 	serverName	100	0	39	167	1
deepSQLStats_diskIOConsumers	U 	ukey	4	10	56	56	0
deepSQLStats_diskIOConsumers	U 	ukey_server	4	10	38	56	1
deepSQLStats_diskIOConsumers	U 	ymd	8	23	111	61	1
deepSQLStats_indexesNotOptimal	U 	databaseName	200	0	39	167	1
deepSQLStats_indexesNotOptimal	U 	indexNumber	4	10	38	56	1
deepSQLStats_indexesNotOptimal	U 	indexSeeks	8	19	108	127	1
deepSQLStats_indexesNotOptimal	U 	isClustered	1	1	50	104	1
deepSQLStats_indexesNotOptimal	U 	serverName	100	0	39	167	1
deepSQLStats_indexesNotOptimal	U 	tableName	500	0	39	167	1
deepSQLStats_indexesNotOptimal	U 	tableScans	8	19	108	127	1
deepSQLStats_indexesNotOptimal	U 	ukey	4	10	56	56	0
deepSQLStats_indexesNotOptimal	U 	ukey_server	4	10	38	56	1
deepSQLStats_indexesNotOptimal	U 	ymd	8	23	111	61	1
deepSQLStats_indexesNotUsed	U 	databaseName	200	0	39	167	1
deepSQLStats_indexesNotUsed	U 	indexName	200	0	39	167	1
deepSQLStats_indexesNotUsed	U 	numUpdates	8	19	108	127	1
deepSQLStats_indexesNotUsed	U 	serverName	100	0	39	167	1
deepSQLStats_indexesNotUsed	U 	tableName	500	0	39	167	1
deepSQLStats_indexesNotUsed	U 	ukey	4	10	56	56	0
deepSQLStats_indexesNotUsed	U 	ukey_server	4	10	38	56	1
deepSQLStats_indexesNotUsed	U 	ymd	8	23	111	61	1
deepSQLStats_memoryAllocation	U 	allocated	8	19	108	127	1
deepSQLStats_memoryAllocation	U 	memoryType	100	0	39	167	1
deepSQLStats_memoryAllocation	U 	serverName	100	0	39	167	1
deepSQLStats_memoryAllocation	U 	ukey	4	10	56	56	0
deepSQLStats_memoryAllocation	U 	ukey_server	4	10	38	56	1
deepSQLStats_memoryAllocation	U 	warning	500	0	39	167	1
deepSQLStats_memoryAllocation	U 	ymd	8	23	111	61	1
deepSQLStats_unindexedTables	U 	databaseName	200	0	39	167	1
deepSQLStats_unindexedTables	U 	serverName	100	0	39	167	1
deepSQLStats_unindexedTables	U 	tableName	500	0	39	167	1
deepSQLStats_unindexedTables	U 	tableScans	8	19	108	127	1
deepSQLStats_unindexedTables	U 	ukey	4	10	56	56	0
deepSQLStats_unindexedTables	U 	ukey_server	4	10	38	56	1
deepSQLStats_unindexedTables	U 	ymd	8	23	111	61	1
dm_performanceCounters	U 	counterName	100	0	39	167	1
dm_performanceCounters	U 	dateAdded	8	23	111	61	1
dm_performanceCounters	U 	ukey	4	10	56	56	0
dm_performanceObjects	U 	dateAdded	8	23	111	61	1
dm_performanceObjects	U 	objectName	100	0	39	167	1
dm_performanceObjects	U 	ukey	4	10	56	56	0
dm_performanceStatThresholds	U 	absolute_alertMax	9	15	106	106	1
dm_performanceStatThresholds	U 	absolute_alertMin	9	15	106	106	1
dm_performanceStatThresholds	U 	relativePercent_alertMax	9	15	106	106	1
dm_performanceStatThresholds	U 	relativePercent_alertMin	9	15	106	106	1
dm_performanceStatThresholds	U 	statName	100	0	39	167	1
dm_performanceStatThresholds	U 	ukey	4	10	56	56	0
dm_serverGroups	U 	groupName	100	0	39	167	1
dm_serverGroups	U 	isProduction	1	1	50	104	1
dm_serverGroups	U 	ukey	4	10	56	56	0
dm_servers	U 	architecture	4	10	38	56	1
dm_servers	U 	blockingSecondsThreshold	8	19	108	127	1
dm_servers	U 	configurationCheck	1	1	50	104	1
dm_servers	U 	configurationCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	configurationCheckSleepUntil	8	23	111	61	1
dm_servers	U 	cpuUtilizationThreshold	8	19	108	127	1
dm_servers	U 	deepSQL2005Check	1	1	50	104	1
dm_servers	U 	deepSQL2005CheckMinuteInterval	4	10	38	56	1
dm_servers	U 	detailedCheck	1	1	50	104	1
dm_servers	U 	detailedCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	diskUtilizationThreshold	8	19	108	127	1
dm_servers	U 	eventLogCheck	1	1	50	104	1
dm_servers	U 	eventLogCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	eventLogCheckSleepUntil	8	23	111	61	1
dm_servers	U 	fragmentationCheck	1	1	50	104	1
dm_servers	U 	fragmentationCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	friendlyName	200	0	39	167	1
dm_servers	U 	ignoreTimeouts	1	1	50	104	1
dm_servers	U 	includeInLongRunningQueries	1	1	50	104	1
dm_servers	U 	indexCheck	1	1	50	104	1
dm_servers	U 	indexCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	installedSoftwareCheck	1	1	50	104	1
dm_servers	U 	installedSoftwareCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	integrityCheck	1	1	50	104	1
dm_servers	U 	integrityCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	isClusterNode	1	1	50	104	1
dm_servers	U 	isEnabled	1	1	50	104	1
dm_servers	U 	isServerPingable	1	1	50	104	1
dm_servers	U 	isSQLAgentServiceRunning	1	1	50	104	1
dm_servers	U 	isSQLBox	1	1	50	104	1
dm_servers	U 	isSQLServiceRunning	1	1	50	104	1
dm_servers	U 	lastConfigurationCheck	8	23	111	61	1
dm_servers	U 	lastDeepSQL2005Check	8	23	111	61	1
dm_servers	U 	lastDetailedCheck	8	23	111	61	1
dm_servers	U 	lastEventLogCheck	8	23	111	61	1
dm_servers	U 	lastFragmentationCheck	8	23	111	61	1
dm_servers	U 	lastIndexCheck	8	23	111	61	1
dm_servers	U 	lastInstalledSoftwareCheck	8	23	111	61	1
dm_servers	U 	lastIntegrityCheck	8	23	111	61	1
dm_servers	U 	lastObjectCheck	8	23	111	61	1
dm_servers	U 	lastPingCheck	8	23	111	61	1
dm_servers	U 	lastSecurityCheck	8	23	111	61	1
dm_servers	U 	lastServiceCheck	8	23	111	61	1
dm_servers	U 	lastTableSizeCheck	8	23	111	61	1
dm_servers	U 	lowPhysicalMemoryThreshold	4	10	38	56	1
dm_servers	U 	lowPoolNonpagedBytesThreshold	4	10	38	56	1
dm_servers	U 	lowPoolPagedBytesThreshold	4	10	38	56	1
dm_servers	U 	lowSpaceThreshold	4	10	38	56	1
dm_servers	U 	lowspaceThresholdRelative	9	10	106	106	1
dm_servers	U 	lowVirtualMemoryThreshold	4	10	38	56	1
dm_servers	U 	maintenanceWindowStart	8	23	111	61	1
dm_servers	U 	maintenanceWindowStop	8	23	111	61	1
dm_servers	U 	multipleBlocksThreshold	4	10	38	56	1
dm_servers	U 	objectChangeCheck	1	1	50	104	1
dm_servers	U 	objectCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	offHoursPriority	4	10	38	56	1
dm_servers	U 	password	100	0	39	167	1
dm_servers	U 	pingCheck	1	1	50	104	1
dm_servers	U 	pingCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	runningMinutesThreshold	4	10	38	56	1
dm_servers	U 	securityCheck	1	1	50	104	1
dm_servers	U 	securityCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	serverName	100	0	39	167	1
dm_servers	U 	serverVersion	2000	0	39	167	1
dm_servers	U 	serviceCheck	1	1	50	104	1
dm_servers	U 	serviceCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	silenceUntil	8	23	111	61	1
dm_servers	U 	skipNextRun	1	1	50	104	1
dm_servers	U 	statisticsCheck	1	1	50	104	1
dm_servers	U 	statisticsCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	summarizeOffHoursJobFailures	1	1	50	104	1
dm_servers	U 	tableSizeCheck	1	1	50	104	1
dm_servers	U 	tableSizeCheckMinuteInterval	4	10	38	56	1
dm_servers	U 	ukey	4	10	56	56	0
dm_servers	U 	ukey_group	4	10	38	56	1
dm_servers	U 	username	100	0	39	167	1
dm_servers	U 	wmiPassword	100	0	39	167	1
dm_servers	U 	wmiStatus	100	0	39	167	1
dm_servers	U 	wmiUsername	100	0	39	167	1
dm_settings	U 	settingName	200	0	39	167	1
dm_settings	U 	settingValue	500	0	39	167	1
dm_settings	U 	ukey	4	10	56	56	0
drivespaceLog	U 	driveLetter	1	0	39	167	1
drivespaceLog	U 	driveSpace	8	19	108	127	1
drivespaceLog	U 	serverName	100	0	39	167	1
drivespaceLog	U 	ukey	4	10	56	56	0
drivespaceLog	U 	ymd	8	23	111	61	1
eventLog	U 	auser	200	0	39	167	1
eventLog	U 	category	200	0	39	167	1
eventLog	U 	computerName	200	0	39	167	1
eventLog	U 	data_timestamp	8	23	111	61	1
eventLog	U 	logType	100	0	39	167	1
eventLog	U 	message	2000	0	39	167	1
eventLog	U 	monitorDate	8	23	111	61	1
eventLog	U 	sourceName	200	0	39	167	1
eventLog	U 	timeWritten	8	23	111	61	1
eventLog	U 	type	200	0	39	167	1
eventLog	U 	ukey	4	10	56	56	0
eventlog_history	U 	notes	1000	0	39	167	1
eventlog_history	U 	serverName	200	0	39	167	1
eventlog_history	U 	ukey	4	10	56	56	0
eventlog_history	U 	ukey_group	4	10	38	56	1
eventlog_history	U 	ymd	8	23	111	61	1
eventLog_stage	U 	auser	200	0	39	167	1
eventLog_stage	U 	category	200	0	39	167	1
eventLog_stage	U 	computerName	200	0	39	167	1
eventLog_stage	U 	logType	100	0	39	167	1
eventLog_stage	U 	message	2000	0	39	167	1
eventLog_stage	U 	monitorDate	8	23	111	61	1
eventLog_stage	U 	sourceName	200	0	39	167	1
eventLog_stage	U 	timeWritten	200	0	39	167	1
eventLog_stage	U 	type	200	0	39	167	1
eventLog_stage_hist	U 	step	200	0	39	167	1
eventLog_stage_hist	U 	ukey_group	4	10	38	56	1
eventLog_stage_hist	U 	ymd	8	23	111	61	1
fn_at	FN	@cSourceString	2000	0	39	167	1
fn_at	FN	@cStringToFind	500	0	39	167	1
fn_at	FN	@nInstance	4	10	38	56	1
fn_capitalize	FN	@cString	500	0	39	167	1
fn_checksum	FN	@cString	-1	0	39	167	1
fn_dateNoTime	FN	@dInputDate	8	23	111	61	1
fn_encodeForGoogleCharts_simple	FN	@nNumber	4	10	38	56	1
fn_hex_to_char	FN	@l	4	10	38	56	1
fn_hex_to_char	FN	@x	100	0	37	165	1
fn_IntToString	FN	@nNumber	8	19	108	127	1
fn_makeTableFromList	TF	@cDelimiter	1	0	39	167	1
fn_makeTableFromList	TF	@cList	8000	0	39	167	1
fn_makeTableFromList	TF	listItem	500	0	39	167	1
fn_makeTableFromList	TF	ukey	4	10	56	56	0
fn_occurs	FN	@cSource	500	0	39	167	1
fn_occurs	FN	@cStringToFind	500	0	39	167	1
fn_padl	FN	@cPadCharacter	1	0	39	167	1
fn_padl	FN	@cString	200	0	39	167	1
fn_padl	FN	@nLength	4	10	38	56	1
fn_padr	FN	@cPadCharacter	1	0	39	167	1
fn_padr	FN	@cString	200	0	39	167	1
fn_padr	FN	@nLength	4	10	38	56	1
fn_removeFormatting	FN	@cString	8000	0	39	167	1
fn_returnDigits	FN	@cSomeString	50	0	39	167	1
fn_returnDigits	FN	@lStopAtFirstNonNumber	1	1	50	104	1
fn_returnFormattedBuffer	FN	@cBuffer	8000	0	39	167	1
fn_returnFormattedInt	FN	@nNumber	8	19	108	127	1
fn_returnKeyValue	FN	@cKey	100	0	39	167	1
fn_returnKeyValue	FN	@cString	500	0	39	167	1
fn_returnKeyValuePair	FN	@cPairDelimiter	10	0	39	167	1
fn_returnKeyValuePair	FN	@cString	500	0	39	167	1
fn_returnKeyValuePair	FN	@nKeyNumber	4	10	38	56	1
fn_returnListItem	FN	@cDelimiter	5	0	39	167	1
fn_returnListItem	FN	@cList	8000	0	39	167	1
fn_returnListItem	FN	@nItemNumber	4	10	38	56	1
fn_returnRunStamp	FN	@dToday	8	23	111	61	1
fn_returnShortDate	FN	@dToday	8	23	111	61	1
fn_returnTrimmedBuffer	FN	@cBufferContents	8000	0	39	167	1
fn_returnUTCDate	FN	@dToday	8	23	111	61	1
fragmentationLog	U 	dbName	200	0	39	167	1
fragmentationLog	U 	extents	8	19	108	127	1
fragmentationLog	U 	extentSwitches	8	19	108	127	1
fragmentationLog	U 	indexName	200	0	39	167	1
fragmentationLog	U 	objectName	200	0	39	167	1
fragmentationLog	U 	rows	8	19	108	127	1
fragmentationLog	U 	scanDensity	13	20	106	106	1
fragmentationLog	U 	ukey	4	10	56	56	0
fragmentationLog	U 	ukey_group	4	10	38	56	1
fragmentationLog	U 	ukey_server	4	10	38	56	1
fragmentationLog	U 	ymd	8	23	111	61	1
hist_partitionTableDaily	U 	stepName	200	0	39	167	1
hist_partitionTableDaily	U 	ymd	8	23	111	61	1
indexPerformanceLog	U 	databaseName	500	0	39	167	1
indexPerformanceLog	U 	indexName	500	0	39	167	1
indexPerformanceLog	U 	serverName	200	0	39	167	1
indexPerformanceLog	U 	tableName	500	0	39	167	1
indexPerformanceLog	U 	ukey_server	4	10	38	56	1
indexPerformanceLog	U 	user_lookups	8	19	108	127	1
indexPerformanceLog	U 	user_scans	8	19	108	127	1
indexPerformanceLog	U 	user_seeks	8	19	108	127	1
indexPerformanceLog	U 	user_updates	8	19	108	127	1
indexPerformanceLog	U 	ymd	8	23	111	61	1
messageRules	U 	allMessages	1	1	50	104	1
messageRules	U 	businessHours	1	1	50	104	1
messageRules	U 	doNotSendMessage	1	1	50	104	1
messageRules	U 	isBlocking	1	1	50	104	1
messageRules	U 	isConfiguration	1	1	50	104	1
messageRules	U 	isConnectivity	1	1	50	104	1
messageRules	U 	isDriveSpace	1	1	50	104	1
messageRules	U 	isEventLog	1	1	50	104	1
messageRules	U 	isFulfillment	1	1	50	104	1
messageRules	U 	isInstalledSoftware	1	1	50	104	1
messageRules	U 	isJobFailure	1	1	50	104	1
messageRules	U 	isLogSize	1	1	50	104	1
messageRules	U 	isLongRunningJob	1	1	50	104	1
messageRules	U 	isLongRunningProcess	1	1	50	104	1
messageRules	U 	isMonitorMessage	1	1	50	104	1
messageRules	U 	isService	1	1	50	104	1
messageRules	U 	messageLike	500	0	39	167	1
messageRules	U 	offHours	1	1	50	104	1
messageRules	U 	sendMessage	1	1	50	104	1
messageRules	U 	serverEquals	100	0	39	167	1
messageRules	U 	serverLike	100	0	39	167	1
messageRules	U 	severity	4	10	38	56	1
messageRules	U 	subjectLike	500	0	39	167	1
messageRules	U 	ukey	4	10	56	56	0
messageRules	U 	ukey_group	4	10	38	56	1
messageRules	U 	ukey_userEmail	4	10	38	56	1
messageRules	U 	userName	100	0	39	167	1
messagesSent	U 	body	8000	0	39	167	1
messagesSent	U 	recipient	100	0	39	167	1
messagesSent	U 	sender	500	0	39	167	1
messagesSent	U 	subject	500	0	39	167	1
messagesSent	U 	ukey	4	10	56	56	0
messagesSent	U 	ymd	8	23	111	61	1
notificationLog	U 	isBlocking	1	1	50	104	1
notificationLog	U 	isConfiguration	1	1	50	104	1
notificationLog	U 	isConnectivity	1	1	50	104	1
notificationLog	U 	isDriveSpace	1	1	50	104	1
notificationLog	U 	isEventLog	1	1	50	104	1
notificationLog	U 	isInstalledSoftware	1	1	50	104	1
notificationLog	U 	isJobFailure	1	1	50	104	1
notificationLog	U 	isLogShippingJobFailure	1	1	50	104	1
notificationLog	U 	isLogSize	1	1	50	104	1
notificationLog	U 	isLongRunningJob	1	1	50	104	1
notificationLog	U 	isLongRunningProcess	1	1	50	104	1
notificationLog	U 	isMonitorMessage	1	1	50	104	1
notificationLog	U 	isService	1	1	50	104	1
notificationLog	U 	message	8000	0	39	167	1
notificationLog	U 	messageSent	1	1	50	104	1
notificationLog	U 	messageSentDate	8	23	111	61	1
notificationLog	U 	serverName	100	0	39	167	1
notificationLog	U 	severity	4	10	38	56	1
notificationLog	U 	subject	300	0	39	167	1
notificationLog	U 	ukey	4	10	56	56	0
notificationLog	U 	ymd	8	23	111	61	1
notificationLog_history	U 	serverName	100	0	39	167	1
notificationLog_history	U 	stepData	4000	0	39	167	1
notificationLog_history	U 	stepName	100	0	39	167	1
notificationLog_history	U 	ukey	4	10	56	56	0
notificationLog_history	U 	ukey_group	4	10	38	56	1
notificationLog_history	U 	ymd	8	23	111	61	1
notificationLog_stage	U 	isBlocking	1	1	50	104	1
notificationLog_stage	U 	isConfiguration	1	1	50	104	1
notificationLog_stage	U 	isConnectivity	1	1	50	104	1
notificationLog_stage	U 	isDriveSpace	1	1	50	104	1
notificationLog_stage	U 	isEventLog	1	1	50	104	1
notificationLog_stage	U 	isInstalledSoftware	1	1	50	104	1
notificationLog_stage	U 	isJobFailure	1	1	50	104	1
notificationLog_stage	U 	isLogShippingJobFailure	1	1	50	104	1
notificationLog_stage	U 	isLogSize	1	1	50	104	1
notificationLog_stage	U 	isLongRunningJob	1	1	50	104	1
notificationLog_stage	U 	isLongRunningProcess	1	1	50	104	1
notificationLog_stage	U 	isMonitorMessage	1	1	50	104	1
notificationLog_stage	U 	isService	1	1	50	104	1
notificationLog_stage	U 	message	8000	0	39	167	1
notificationLog_stage	U 	serverName	100	0	39	167	1
notificationLog_stage	U 	severity	4	10	38	56	1
notificationLog_stage	U 	subject	300	0	39	167	1
notificationLog_stage	U 	ukey	4	10	56	56	0
notificationLog_stage	U 	ymd	8	23	111	61	1
notificationsSent	U 	dateSent	8	23	111	61	1
notificationsSent	U 	emailAddress	100	0	39	167	1
notificationsSent	U 	ukey	4	10	56	56	0
notificationsSent	U 	ukey_notification	8	19	108	127	1
notificationsSent	U 	userName	100	0	39	167	1
performanceLog	U 	counterType	8	19	108	127	1
performanceLog	U 	counterValue	8	19	108	127	1
performanceLog	U 	instanceName	255	0	39	167	1
performanceLog	U 	runStamp	8	19	108	127	1
performanceLog	U 	ukey	8	19	63	127	0
performanceLog	U 	ukey_counter	4	10	56	56	0
performanceLog	U 	ukey_object	4	10	56	56	0
performanceLog	U 	ukey_server	4	10	56	56	0
performanceLog	U 	ymd	8	23	111	61	1
performanceLog_daily	U 	counterType	8	19	108	127	1
performanceLog_daily	U 	counterValue	8	19	108	127	1
performanceLog_daily	U 	instanceName	255	0	39	167	1
performanceLog_daily	U 	runStamp	8	19	108	127	1
performanceLog_daily	U 	ukey	8	19	63	127	0
performanceLog_daily	U 	ukey_counter	4	10	56	56	0
performanceLog_daily	U 	ukey_object	4	10	56	56	0
performanceLog_daily	U 	ukey_server	4	10	56	56	0
performanceLog_daily	U 	ymd	8	23	111	61	1
performanceLog_stage	U 	counterName	255	0	39	167	1
performanceLog_stage	U 	counterType	8	19	108	127	1
performanceLog_stage	U 	counterValue	8	19	108	127	1
performanceLog_stage	U 	instanceName	255	0	39	167	1
performanceLog_stage	U 	objectName	255	0	39	167	1
performanceLog_stage	U 	runStamp	8	19	108	127	1
performanceLog_stage	U 	serverName	200	0	39	167	1
performanceLog_stage	U 	ukey	8	19	63	127	0
performanceLog_stage	U 	ymd	8	23	111	61	1
pingLog	U 	friendlyName	100	0	39	167	1
pingLog	U 	isRouterPingable	1	1	50	104	1
pingLog	U 	isServerPingable	1	1	50	104	1
pingLog	U 	isSQLPingable	1	1	50	104	1
pingLog	U 	routerPingResults	2000	0	39	167	1
pingLog	U 	serverName	100	0	39	167	1
pingLog	U 	serverPingResults	2000	0	39	167	1
pingLog	U 	sqlPingResults	2000	0	39	167	1
pingLog	U 	ukey	4	10	56	56	0
pingLog	U 	ymd	8	23	111	61	1
pr_alert_replicationSynchronization	P 	@cDatabaseName	100	0	39	167	1
pr_alert_replicationSynchronization	P 	@cServerName_Publisher	100	0	39	167	1
pr_alert_replicationSynchronization	P 	@cServerName_Subscriber	100	0	39	167	1
pr_archiveOldLinkedPartitionedTables	P 	@cForeignKeyField	100	0	39	167	1
pr_archiveOldLinkedPartitionedTables	P 	@cForeignTable	100	0	39	167	1
pr_archiveOldLinkedPartitionedTables	P 	@cForeignTableDateField	100	0	39	167	1
pr_archiveOldLinkedPartitionedTables	P 	@cForeignTableKeyField	100	0	39	167	1
pr_archiveOldLinkedPartitionedTables	P 	@cKeyfieldList	100	0	39	167	1
pr_archiveOldLinkedPartitionedTables	P 	@cTableName	100	0	39	167	1
pr_archiveOldPartitionedTables	P 	@cDateField	100	0	39	167	1
pr_archiveOldPartitionedTables	P 	@cKeyfieldList	100	0	39	167	1
pr_archiveOldPartitionedTables	P 	@cTableName	100	0	39	167	1
pr_checkFragmentation	P 	@nServerGroup	4	10	38	56	1
pr_checkIntegrity	P 	@nServerGroup	4	10	38	56	1
pr_checkServices	P 	@nUkeyGroup	4	10	38	56	1
pr_dashboard_returnAlerts	P 	@cServerName	100	0	39	167	1
pr_dashboard_returnAlerts	P 	@nNumHours	4	10	38	56	1
pr_dashboard_returnEventlogMessages	P 	@cServerName	100	0	39	167	1
pr_dashboard_returnMessageRules	P 	@cUserName	100	0	39	167	1
pr_dashboard_serverStatus	P 	@cUserName	100	0	39	167	1
pr_dashboard_silenceAlert	P 	@cMessage	500	0	39	167	1
pr_dashboard_silenceAlert	P 	@cMessageSource	100	0	39	167	1
pr_dashboard_silenceAlert	P 	@cServerName	100	0	39	167	1
pr_dashboard_silenceAlert	P 	@cUserName	100	0	39	167	1
pr_examineAllServers	P 	@nServerGroup	4	10	38	56	1
pr_examineServer	P 	@cServerName	100	0	39	167	1
pr_examineServer	P 	@nMinutesBackToLook	4	10	38	56	1
pr_generateGoogleChartsRequest	P 	@bAbsoluteYAxis	1	1	50	104	1
pr_generateGoogleChartsRequest	P 	@bLeavePeaks	1	1	50	104	1
pr_generateGoogleChartsRequest	P 	@bRelativeToTotal	1	1	50	104	1
pr_generateGoogleChartsRequest	P 	@bShowPie	1	1	50	104	1
pr_generateGoogleChartsRequest	P 	@nHeight	4	10	38	56	1
pr_generateGoogleChartsRequest	P 	@nWidth	4	10	38	56	1
pr_graph_bufferContents	P 	@cServerName	100	0	39	167	1
pr_graph_bufferContents	P 	@dEndDate	8	23	111	61	1
pr_graph_bufferContents	P 	@dStartDate	8	23	111	61	1
pr_graph_connectionsByHour	P 	@cServerName	100	0	39	167	1
pr_graph_connectionsByHour	P 	@nGraphWidth	4	10	38	56	1
pr_graph_sqlCPULoad_byDatabase_byHour	P 	@cServerName	100	0	39	167	1
pr_graph_sqlCPULoad_byDatabase_pie	P 	@cServerName	100	0	39	167	1
pr_graph_sqlDiskLoad_byDatabase_byHour	P 	@cServerName	100	0	39	167	1
pr_graph_sqlDiskLoad_byDatabase_pie	P 	@cServerName	100	0	39	167	1
pr_graph_sqlLoadByHour	P 	@cServerName	100	0	39	167	1
pr_graph_sqlLoadByHour	P 	@nGraphWidth	4	10	38	56	1
pr_monitorFile	P 	@cFileToMonitor	500	0	39	167	1
pr_monitorFile	P 	@cServerName	200	0	39	167	1
pr_monitorFile	P 	@cStringToFind	100	0	39	167	1
pr_partitionLinkedTableDaily	P 	@cForeignKeyField	100	0	39	167	1
pr_partitionLinkedTableDaily	P 	@cForeignTable	100	0	39	167	1
pr_partitionLinkedTableDaily	P 	@cForeignTableDateField	100	0	39	167	1
pr_partitionLinkedTableDaily	P 	@cForeignTableKeyField	100	0	39	167	1
pr_partitionLinkedTableDaily	P 	@cKeyfieldList	100	0	39	167	1
pr_partitionLinkedTableDaily	P 	@cTableName	100	0	39	167	1
pr_partitionLinkedTableDaily	P 	@lMakeUkey	1	1	50	104	1
pr_partitionTableDaily	P 	@cDateField	100	0	39	167	1
pr_partitionTableDaily	P 	@cKeyfieldList	100	0	39	167	1
pr_partitionTableDaily	P 	@cTableName	100	0	39	167	1
pr_partitionTableDaily	P 	@lMakeUkey	1	1	50	104	1
pr_pingServer	P 	@cServerName	100	0	39	167	1
pr_pingSoloServers	P 	@nGroupToCheck	4	10	38	56	1
pr_processEventLogMessages	P 	@nUkeyGroup	4	10	38	56	1
pr_queryProcessLog	P 	@bJustBlocking	1	1	50	104	1
pr_queryProcessLog	P 	@bJustRunning	1	1	50	104	1
pr_queryProcessLog	P 	@cBuffer	500	0	39	167	1
pr_queryProcessLog	P 	@cDatabaseName	100	0	39	167	1
pr_queryProcessLog	P 	@cHostName	100	0	39	167	1
pr_queryProcessLog	P 	@cLocks	100	0	39	167	1
pr_queryProcessLog	P 	@cLogin	100	0	39	167	1
pr_queryProcessLog	P 	@cProgramName	100	0	39	167	1
pr_queryProcessLog	P 	@cServerName	100	0	39	167	1
pr_queryProcessLog	P 	@dEndDate	8	23	111	61	1
pr_queryProcessLog	P 	@dStartDate	8	23	111	61	1
pr_queryProcessLog	P 	@nMinCPU	4	10	38	56	1
pr_queryProcessLog	P 	@nMinDisk	4	10	38	56	1
pr_queryProcessLog	P 	@nMinRuntime	4	10	38	56	1
pr_queryProcessLog	P 	@nMinWait	4	10	38	56	1
pr_queryProcessLog	P 	@nNumHours	4	10	38	56	1
pr_rpt_allTableSizes	P 	@cServerName	200	0	39	167	1
pr_rpt_backupSummary	P 	@cServerName	200	0	39	167	1
pr_rpt_blockedQueries	P 	@cServerName	100	0	39	167	1
pr_rpt_blockedQueries	P 	@nNumHours	4	10	38	56	1
pr_rpt_blockingQueries	P 	@cServerName	100	0	39	167	1
pr_rpt_blockingQueries	P 	@nNumHours	4	10	38	56	1
pr_rpt_bufferCache_databaseWeek	P 	@cServerName	100	0	39	167	1
pr_rpt_bufferCache_tableWeek	P 	@cServerName	100	0	39	167	1
pr_rpt_bufferCacheContents	P 	@cServerName	100	0	39	167	1
pr_rpt_bufferCacheContents	P 	@dEndDate	8	23	111	61	1
pr_rpt_bufferCacheContents	P 	@dStartDate	8	23	111	61	1
pr_rpt_bufferContents	P 	@cServerName	100	0	39	167	1
pr_rpt_bufferContents	P 	@dEndDate	8	23	111	61	1
pr_rpt_bufferContents	P 	@dStartDate	8	23	111	61	1
pr_rpt_cpuCycles	P 	@cServerName	100	0	39	167	1
pr_rpt_cpuCycles	P 	@dEndDate	8	23	111	61	1
pr_rpt_cpuCycles	P 	@dStartDate	8	23	111	61	1
pr_rpt_databaseActivitySummary	P 	@cServerName	100	0	39	167	1
pr_rpt_databaseFileGrowthHistory	P 	@cServerName	100	0	39	167	1
pr_rpt_databaseFileGrowthHistory	P 	@dStartDate	8	23	111	61	1
pr_rpt_databaseGrowthDetail	P 	@cServerName	100	0	39	167	1
pr_rpt_databaseGrowthSummary	P 	@cServerName	100	0	39	167	1
pr_rpt_databaseLastUserActivity	P 	@cServerName	200	0	39	167	1
pr_rpt_deepScanChronological	P 	@cServerName	100	0	39	167	1
pr_rpt_deepScanChronological	P 	@dEndDate	8	23	111	61	1
pr_rpt_deepScanChronological	P 	@dStartDate	8	23	111	61	1
pr_rpt_diskIO	P 	@cServerName	100	0	39	167	1
pr_rpt_diskIO	P 	@dEndDate	8	23	111	61	1
pr_rpt_diskIO	P 	@dStartDate	8	23	111	61	1
pr_rpt_diskIOHistory	P 	@cServerName	100	0	39	167	1
pr_rpt_diskIOHistory	P 	@dEndDate	8	23	111	61	1
pr_rpt_diskIOHistory	P 	@dStartDate	8	23	111	61	1
pr_rpt_diskQueuesByHour	P 	@cServerName	100	0	39	167	1
pr_rpt_enterprisePacketLoss	P 	@dEndDate	8	23	111	61	1
pr_rpt_enterprisePacketLoss	P 	@dStartDate	8	23	111	61	1
pr_rpt_fragmentation	P 	@cServerName	100	0	39	167	1
pr_rpt_heaviestLoadOverTime	P 	@cServerName	100	0	39	167	1
pr_rpt_heaviestLoadOverTime	P 	@nHours	4	10	38	56	1
pr_rpt_indexAnalysis	P 	@cServerName	100	0	39	167	1
pr_rpt_indexAnalysis	P 	@dEndDate	8	23	111	61	1
pr_rpt_indexAnalysis	P 	@dStartDate	8	23	111	61	1
pr_rpt_indexAnalysis_badClustered	P 	@cServerName	100	0	39	167	1
pr_rpt_indexAnalysis_notUsed	P 	@cServerName	100	0	39	167	1
pr_rpt_indexAnalysis_unindexed	P 	@cServerName	100	0	39	167	1
pr_rpt_indexSummary	P 	@cServerName	200	0	39	167	1
pr_rpt_indexSummary	P 	@nNumHours	4	10	38	56	1
pr_rpt_installedSoftwareChanges	P 	@dEndDate	8	23	111	61	1
pr_rpt_installedSoftwareChanges	P 	@dStartDate	8	23	111	61	1
pr_rpt_jobHistory	P 	@cServerName	200	0	39	167	1
pr_rpt_jobHistory	P 	@dStartDate	8	23	111	61	1
pr_rpt_jobHistory	P 	@nMinuteInterval	4	10	38	56	1
pr_rpt_longRunningOLEDBQueries	P 	@cServerName	100	0	39	167	1
pr_rpt_longRunningOLEDBQueries	P 	@nNumHours	4	10	38	56	1
pr_rpt_longRunningQueries	P 	@cServerName	200	0	39	167	1
pr_rpt_longRunningQueries	P 	@nNumHours	4	10	38	56	1
pr_rpt_memoryAllocation	P 	@cServerName	100	0	39	167	1
pr_rpt_memoryAllocation	P 	@dEndDate	8	23	111	61	1
pr_rpt_memoryAllocation	P 	@dStartDate	8	23	111	61	1
pr_rpt_mostRunQueries	P 	@cServerName	100	0	39	167	1
pr_rpt_mostRunQueries	P 	@dEndDate	8	23	111	61	1
pr_rpt_mostRunQueries	P 	@dStartDate	8	23	111	61	1
pr_rpt_outages_detail	P 	@dEndDate	8	23	111	61	1
pr_rpt_outages_detail	P 	@dStartDate	8	23	111	61	1
pr_rpt_outages_summary	P 	@dEndDate	8	23	111	61	1
pr_rpt_outages_summary	P 	@dStartDate	8	23	111	61	1
pr_rpt_parallelism	P 	@cServerName	100	0	39	167	1
pr_rpt_queryDetail	P 	@cServerName	100	0	39	167	1
pr_rpt_queryDetail	P 	@dEndDate	8	23	111	61	1
pr_rpt_queryDetail	P 	@dStartDate	8	23	111	61	1
pr_rpt_querySummary	P 	@cServerName	100	0	39	167	1
pr_rpt_querySummary	P 	@nHours	4	10	38	56	1
pr_rpt_recompiledObjects	P 	@cServerName	100	0	39	167	1
pr_rpt_recompiledObjects	P 	@nNumHours	4	10	38	56	1
pr_rpt_serverWaits	P 	@cServerName	100	0	39	167	1
pr_rpt_serverWaits	P 	@dEndDate	8	23	111	61	1
pr_rpt_serverWaits	P 	@dStartDate	8	23	111	61	1
pr_rpt_sqlBlockingDetail	P 	@cServerName	100	0	39	167	1
pr_rpt_sqlBlockingDetail	P 	@nNumHours	4	10	38	56	1
pr_rpt_sqlCPUWaits	P 	@cServerName	100	0	39	167	1
pr_rpt_sqlCPUWaits	P 	@nNumHours	4	10	38	56	1
pr_rpt_sqlDiskWaiting	P 	@cServerName	100	0	39	167	1
pr_rpt_sqlDiskWaiting	P 	@nNumHours	4	10	38	56	1
pr_rpt_sqlLoadByDatabaseByMinute	P 	@cServerName	100	0	39	167	1
pr_rpt_sqlLoadByDatabaseByMinute	P 	@dEndDate	8	23	111	61	1
pr_rpt_sqlLoadByDatabaseByMinute	P 	@dStartDate	8	23	111	61	1
pr_rpt_SQLSummary	P 	@cServerName	100	0	39	167	1
pr_rpt_tableSizes	P 	@cServerName	100	0	39	167	1
pr_rpt_waitTypesSummary	P 	@cServerName	100	0	39	167	1
pr_sendAlerts	P 	@bIsPreview	1	1	50	104	1
pr_sendAlerts	P 	@cUserName	100	0	39	167	1
pr_sendMessage	P 	@cBody	8000	0	39	167	1
pr_sendMessage	P 	@cFrom	100	0	39	167	1
pr_sendMessage	P 	@cSubject	500	0	39	167	1
pr_sendMessage	P 	@cTo	500	0	39	167	1
processLog	U 	blockedBy	20	0	39	167	1
processLog	U 	buffercontents	3000	0	39	167	1
processLog	U 	command	100	0	39	167	1
processLog	U 	cputime	4	10	38	56	1
processLog	U 	dbName	128	0	39	167	1
processLog	U 	diskio	4	10	38	56	1
processLog	U 	hostname	128	0	39	167	1
processLog	U 	isBlocked	1	1	50	104	1
processLog	U 	isBlocker	1	1	50	104	1
processLog	U 	isWild	1	1	50	104	1
processLog	U 	lastBatch	100	0	39	167	1
processLog	U 	lastBatchTime	8	23	111	61	1
processLog	U 	lastWaitType	32	0	39	167	1
processLog	U 	locks	4000	0	39	167	1
processLog	U 	login	100	0	39	167	1
processLog	U 	login_time	8	23	111	61	1
processLog	U 	net_address	12	0	39	167	1
processLog	U 	programName	100	0	39	167	1
processLog	U 	serverName	200	0	39	167	1
processLog	U 	spid	4	10	38	56	1
processLog	U 	sql_handle	20	0	37	173	1
processLog	U 	status	100	0	39	167	1
processLog	U 	ukey	4	10	56	56	0
processLog	U 	waitResource	256	0	39	167	1
processLog	U 	waitTime	8	19	108	127	1
processLog	U 	waitType	2	0	37	173	1
processLog	U 	ymd	8	23	111	61	1
processLog_daily	U 	blockedBy	20	0	39	167	1
processLog_daily	U 	buffercontents	3000	0	39	167	1
processLog_daily	U 	command	100	0	39	167	1
processLog_daily	U 	cputime	4	10	38	56	1
processLog_daily	U 	dbName	128	0	39	167	1
processLog_daily	U 	diskio	4	10	38	56	1
processLog_daily	U 	hostname	128	0	39	167	1
processLog_daily	U 	isBlocked	1	1	50	104	1
processLog_daily	U 	isBlocker	1	1	50	104	1
processLog_daily	U 	isWild	1	1	50	104	1
processLog_daily	U 	lastBatch	100	0	39	167	1
processLog_daily	U 	lastBatchTime	8	23	111	61	1
processLog_daily	U 	lastWaitType	32	0	39	167	1
processLog_daily	U 	locks	4000	0	39	167	1
processLog_daily	U 	login	100	0	39	167	1
processLog_daily	U 	login_time	8	23	111	61	1
processLog_daily	U 	net_address	12	0	39	167	1
processLog_daily	U 	programName	100	0	39	167	1
processLog_daily	U 	serverName	200	0	39	167	1
processLog_daily	U 	spid	4	10	38	56	1
processLog_daily	U 	sql_handle	20	0	37	173	1
processLog_daily	U 	status	100	0	39	167	1
processLog_daily	U 	ukey	4	10	56	56	0
processLog_daily	U 	waitResource	256	0	39	167	1
processLog_daily	U 	waitTime	8	19	108	127	1
processLog_daily	U 	waitType	2	0	37	173	1
processLog_daily	U 	ymd	8	23	111	61	1
processLog_stage	U 	blockedBy	20	0	39	167	1
processLog_stage	U 	buffercontents	3000	0	39	167	1
processLog_stage	U 	command	100	0	39	167	1
processLog_stage	U 	cputime	4	10	38	56	1
processLog_stage	U 	dbName	128	0	39	167	1
processLog_stage	U 	diskio	4	10	38	56	1
processLog_stage	U 	hostname	128	0	39	167	1
processLog_stage	U 	isBlocked	1	1	50	104	1
processLog_stage	U 	isBlocker	1	1	50	104	1
processLog_stage	U 	isWild	1	1	50	104	1
processLog_stage	U 	lastBatch	100	0	39	167	1
processLog_stage	U 	lastBatchTime	8	23	111	61	1
processLog_stage	U 	lastWaitType	32	0	39	167	1
processLog_stage	U 	locks	4000	0	39	167	1
processLog_stage	U 	login	100	0	39	167	1
processLog_stage	U 	login_time	8	23	111	61	1
processLog_stage	U 	net_address	12	0	39	167	1
processLog_stage	U 	programName	100	0	39	167	1
processLog_stage	U 	serverName	200	0	39	167	1
processLog_stage	U 	spid	4	10	38	56	1
processLog_stage	U 	sql_handle	20	0	37	173	1
processLog_stage	U 	status	100	0	39	167	1
processLog_stage	U 	ukey	4	10	56	56	0
processLog_stage	U 	waitResource	256	0	39	167	1
processLog_stage	U 	waitTime	8	19	108	127	1
processLog_stage	U 	waitType	2	0	37	173	1
processLog_stage	U 	ymd	8	23	111	61	1
queue_messages_1977058079	IT	binary_message_body	-1	0	37	165	1
queue_messages_1977058079	IT	conversation_group_id	16	0	37	36	0
queue_messages_1977058079	IT	conversation_handle	16	0	37	36	0
queue_messages_1977058079	IT	fragment_bitmap	8	19	63	127	0
queue_messages_1977058079	IT	fragment_size	4	10	56	56	0
queue_messages_1977058079	IT	message_id	16	0	37	36	0
queue_messages_1977058079	IT	message_sequence_number	8	19	63	127	0
queue_messages_1977058079	IT	message_type_id	4	10	56	56	0
queue_messages_1977058079	IT	next_fragment	4	10	56	56	0
queue_messages_1977058079	IT	priority	1	3	48	48	0
queue_messages_1977058079	IT	queuing_order	8	19	63	127	0
queue_messages_1977058079	IT	service_contract_id	4	10	56	56	0
queue_messages_1977058079	IT	service_id	4	10	56	56	0
queue_messages_1977058079	IT	status	1	3	48	48	0
queue_messages_1977058079	IT	validation	2	0	47	239	0
queue_messages_2009058193	IT	binary_message_body	-1	0	37	165	1
queue_messages_2009058193	IT	conversation_group_id	16	0	37	36	0
queue_messages_2009058193	IT	conversation_handle	16	0	37	36	0
queue_messages_2009058193	IT	fragment_bitmap	8	19	63	127	0
queue_messages_2009058193	IT	fragment_size	4	10	56	56	0
queue_messages_2009058193	IT	message_id	16	0	37	36	0
queue_messages_2009058193	IT	message_sequence_number	8	19	63	127	0
queue_messages_2009058193	IT	message_type_id	4	10	56	56	0
queue_messages_2009058193	IT	next_fragment	4	10	56	56	0
queue_messages_2009058193	IT	priority	1	3	48	48	0
queue_messages_2009058193	IT	queuing_order	8	19	63	127	0
queue_messages_2009058193	IT	service_contract_id	4	10	56	56	0
queue_messages_2009058193	IT	service_id	4	10	56	56	0
queue_messages_2009058193	IT	status	1	3	48	48	0
queue_messages_2009058193	IT	validation	2	0	47	239	0
queue_messages_2041058307	IT	binary_message_body	-1	0	37	165	1
queue_messages_2041058307	IT	conversation_group_id	16	0	37	36	0
queue_messages_2041058307	IT	conversation_handle	16	0	37	36	0
queue_messages_2041058307	IT	fragment_bitmap	8	19	63	127	0
queue_messages_2041058307	IT	fragment_size	4	10	56	56	0
queue_messages_2041058307	IT	message_id	16	0	37	36	0
queue_messages_2041058307	IT	message_sequence_number	8	19	63	127	0
queue_messages_2041058307	IT	message_type_id	4	10	56	56	0
queue_messages_2041058307	IT	next_fragment	4	10	56	56	0
queue_messages_2041058307	IT	priority	1	3	48	48	0
queue_messages_2041058307	IT	queuing_order	8	19	63	127	0
queue_messages_2041058307	IT	service_contract_id	4	10	56	56	0
queue_messages_2041058307	IT	service_id	4	10	56	56	0
queue_messages_2041058307	IT	status	1	3	48	48	0
queue_messages_2041058307	IT	validation	2	0	47	239	0
serviceLog	U 	serverName	200	0	39	167	1
serviceLog	U 	serviceName	200	0	39	167	1
serviceLog	U 	ukey	4	10	56	56	0
serviceLog	U 	ukey_run	4	10	38	56	1
serviceLog	U 	ymd	8	23	111	61	1
serviceLog_runs	U 	ukey	4	10	56	56	0
serviceLog_runs	U 	ymd	8	23	111	61	1
sp_send_cdosysmail	P 	@AttachmentPath	1000	0	39	167	1
sp_send_cdosysmail	P 	@Body	8000	0	39	167	1
sp_send_cdosysmail	P 	@From	100	0	39	167	1
sp_send_cdosysmail	P 	@Subject	100	0	39	167	1
sp_send_cdosysmail	P 	@To	100	0	39	167	1
tableSizeLog	U 	data	50	0	39	167	1
tableSizeLog	U 	databaseName	200	0	39	167	1
tableSizeLog	U 	indexSize	50	0	39	167	1
tableSizeLog	U 	reserved	50	0	39	167	1
tableSizeLog	U 	rows	100	0	39	167	1
tableSizeLog	U 	serverName	200	0	39	167	1
tableSizeLog	U 	tableName	200	0	39	167	1
tableSizeLog	U 	unused	50	0	39	167	1
tableSizeLog	U 	ymd	8	23	111	61	1
userEmails	U 	emailAddress	100	0	39	167	1
userEmails	U 	ukey	4	10	56	56	0
userEmails	U 	userName	100	0	39	167	1
v_databaseFileSizeLog_all	V 	dbname	100	0	39	167	0
v_databaseFileSizeLog_all	V 	fileName	100	0	39	167	1
v_databaseFileSizeLog_all	V 	isLog	1	1	50	104	1
v_databaseFileSizeLog_all	V 	objectname	100	0	39	167	1
v_databaseFileSizeLog_all	V 	serverName	200	0	39	167	0
v_databaseFileSizeLog_all	V 	size	8	19	108	127	1
v_databaseFileSizeLog_all	V 	ukey	4	10	56	56	0
v_databaseFileSizeLog_all	V 	ymd	8	23	61	61	0
v_drivespaceLog_all	V 	driveLetter	1	0	39	167	0
v_drivespaceLog_all	V 	driveSpace	8	19	108	127	1
v_drivespaceLog_all	V 	serverName	100	0	39	167	0
v_drivespaceLog_all	V 	ukey	4	10	56	56	0
v_drivespaceLog_all	V 	ymd	8	23	61	61	0
v_eventLog_all	V 	auser	200	0	39	167	1
v_eventLog_all	V 	category	200	0	39	167	1
v_eventLog_all	V 	computerName	200	0	39	167	0
v_eventLog_all	V 	data_timestamp	8	23	61	61	0
v_eventLog_all	V 	logType	100	0	39	167	1
v_eventLog_all	V 	message	2000	0	39	167	1
v_eventLog_all	V 	monitorDate	8	23	111	61	1
v_eventLog_all	V 	sourceName	200	0	39	167	1
v_eventLog_all	V 	timeWritten	8	23	111	61	1
v_eventLog_all	V 	type	200	0	39	167	1
v_eventLog_all	V 	ukey	4	10	56	56	0
v_getDate	V 	ymd	8	23	61	61	0
v_notificationLog_all	V 	isBlocking	1	1	50	104	1
v_notificationLog_all	V 	isConfiguration	1	1	50	104	1
v_notificationLog_all	V 	isConnectivity	1	1	50	104	1
v_notificationLog_all	V 	isDriveSpace	1	1	50	104	1
v_notificationLog_all	V 	isEventLog	1	1	50	104	1
v_notificationLog_all	V 	isInstalledSoftware	1	1	50	104	1
v_notificationLog_all	V 	isJobFailure	1	1	50	104	1
v_notificationLog_all	V 	isLogShippingJobFailure	1	1	50	104	1
v_notificationLog_all	V 	isLogSize	1	1	50	104	1
v_notificationLog_all	V 	isLongRunningJob	1	1	50	104	1
v_notificationLog_all	V 	isLongRunningProcess	1	1	50	104	1
v_notificationLog_all	V 	isMonitorMessage	1	1	50	104	1
v_notificationLog_all	V 	isService	1	1	50	104	1
v_notificationLog_all	V 	message	8000	0	39	167	1
v_notificationLog_all	V 	messageSent	1	1	50	104	1
v_notificationLog_all	V 	messageSentDate	8	23	111	61	1
v_notificationLog_all	V 	serverName	100	0	39	167	0
v_notificationLog_all	V 	severity	4	10	38	56	1
v_notificationLog_all	V 	subject	300	0	39	167	1
v_notificationLog_all	V 	ukey	4	10	56	56	0
v_notificationLog_all	V 	ymd	8	23	61	61	0
v_performanceLog_all	V 	counterType	8	19	108	127	1
v_performanceLog_all	V 	counterValue	8	19	108	127	1
v_performanceLog_all	V 	instanceName	255	0	39	167	0
v_performanceLog_all	V 	runStamp	8	19	63	127	0
v_performanceLog_all	V 	ukey	8	19	63	127	0
v_performanceLog_all	V 	ukey_counter	4	10	56	56	0
v_performanceLog_all	V 	ukey_object	4	10	56	56	0
v_performanceLog_all	V 	ukey_server	4	10	56	56	0
v_performanceLog_all	V 	ymd	8	23	61	61	0
v_pingLog_all	V 	friendlyName	100	0	39	167	1
v_pingLog_all	V 	isRouterPingable	1	1	50	104	1
v_pingLog_all	V 	isServerPingable	1	1	50	104	1
v_pingLog_all	V 	isSQLPingable	1	1	50	104	1
v_pingLog_all	V 	routerPingResults	2000	0	39	167	1
v_pingLog_all	V 	serverName	100	0	39	167	0
v_pingLog_all	V 	serverPingResults	2000	0	39	167	1
v_pingLog_all	V 	sqlPingResults	2000	0	39	167	1
v_pingLog_all	V 	ukey	4	10	56	56	0
v_pingLog_all	V 	ymd	8	23	61	61	0
v_processLog_all	V 	blockedBy	20	0	39	167	1
v_processLog_all	V 	buffercontents	3000	0	39	167	1
v_processLog_all	V 	command	100	0	39	167	1
v_processLog_all	V 	cputime	4	10	38	56	1
v_processLog_all	V 	dbName	128	0	39	167	1
v_processLog_all	V 	diskio	4	10	38	56	1
v_processLog_all	V 	hostname	128	0	39	167	1
v_processLog_all	V 	isBlocked	1	1	50	104	1
v_processLog_all	V 	isBlocker	1	1	50	104	1
v_processLog_all	V 	isWild	1	1	50	104	1
v_processLog_all	V 	lastBatch	100	0	39	167	1
v_processLog_all	V 	lastBatchTime	8	23	111	61	1
v_processLog_all	V 	lastWaitType	32	0	39	167	1
v_processLog_all	V 	locks	4000	0	39	167	1
v_processLog_all	V 	login	100	0	39	167	1
v_processLog_all	V 	login_time	8	23	111	61	1
v_processLog_all	V 	net_address	12	0	39	167	1
v_processLog_all	V 	programName	100	0	39	167	1
v_processLog_all	V 	serverName	200	0	39	167	0
v_processLog_all	V 	spid	4	10	56	56	0
v_processLog_all	V 	sql_handle	20	0	37	173	1
v_processLog_all	V 	status	100	0	39	167	1
v_processLog_all	V 	ukey	4	10	56	56	0
v_processLog_all	V 	waitResource	256	0	39	167	1
v_processLog_all	V 	waitTime	8	19	108	127	1
v_processLog_all	V 	waitType	2	0	37	173	1
v_processLog_all	V 	ymd	8	23	61	61	0
watchedConnections	U 	alertEmail	200	0	39	167	1
watchedConnections	U 	dbName	100	0	39	167	1
watchedConnections	U 	hostname	100	0	39	167	1
watchedConnections	U 	login	100	0	39	167	1
watchedConnections	U 	programName	100	0	39	167	1
watchedConnections	U 	serverName	200	0	39	167	1
watchedConnections	U 	ukey	4	10	56	56	0

========================================
========================================
Indexes
========================================
========================================
name	name	xtype	name	keyno
databaseFileSizeLog	ix_databaseFileSizeLog_compound	U 	ymd	1
databaseFileSizeLog	ix_databaseFileSizeLog_compound	U 	serverName	2
databaseFileSizeLog	ix_databaseFileSizeLog_compound	U 	isLog	3
databaseFileSizeLog	ix_databaseFileSizeLog_compound	U 	dbname	4
databaseFileSizeLog	ix_databaseFileSizeLog_serverName	U 	serverName	1
databaseFileSizeLog	ix_databaseFileSizeLog_serverName	U 	isLog	2
databaseFileSizeLog	ix_databaseFileSizeLog_serverName	U 	dbname	3
databaseFileSizeLog	ix_databaseFileSizeLog_serverName	U 	ymd	4
databaseFileSizeLog	ix_databaseFileSizeLog_ymd_isLog	U 	ymd	1
databaseFileSizeLog	ix_databaseFileSizeLog_ymd_isLog	U 	isLog	2
databaseFileSizeLog	ix_databaseFileSizeLog_ymd_isLog	U 	dbname	3
databaseFileSizeLog	ix_databaseFileSizeLog_ymd_isLog	U 	serverName	4
databaseFileSizeLog_stage	ix_databaseFileSizeLogStage	U 	ymd	1
databaseFileSizeLog_stage	ix_databaseFileSizeLogStage	U 	serverName	2
databaseFileSizeLog_stage	ix_databaseFileSizeLogStage	U 	dbname	3
deepSQLStats	ix_deepSQLStats_compound	U 	ymd	1
deepSQLStats	ix_deepSQLStats_compound	U 	serverName	2
deepSQLStats	ix_deepSQLStats_serverName_ymd_keyName_subkeyName	U 	serverName	1
deepSQLStats	ix_deepSQLStats_serverName_ymd_keyName_subkeyName	U 	ymd	2
deepSQLStats	ix_deepSQLStats_serverName_ymd_keyName_subkeyName	U 	keyName	3
deepSQLStats	ix_deepSQLStats_serverName_ymd_keyName_subkeyName	U 	subkeyName	4
deepSQLStats_bufferCache	ix_deepSQLStats_bufferCache_ymd_serverName_databaseName_tableName_indexNumber	U 	ymd	1
deepSQLStats_bufferCache	ix_deepSQLStats_bufferCache_ymd_serverName_databaseName_tableName_indexNumber	U 	serverName	2
deepSQLStats_bufferCache	ix_deepSQLStats_bufferCache_ymd_serverName_databaseName_tableName_indexNumber	U 	databaseName	3
deepSQLStats_bufferCache	ix_deepSQLStats_bufferCache_ymd_serverName_databaseName_tableName_indexNumber	U 	tableName	4
deepSQLStats_bufferCache	ix_deepSQLStats_bufferCache_ymd_serverName_databaseName_tableName_indexNumber	U 	indexNumber	5
deepSQLStats_indexesNotOptimal	ix_deepSQLStats_indexesNotOptimal_serverName_databaseName_tableName_indexNumber	U 	serverName	1
deepSQLStats_indexesNotOptimal	ix_deepSQLStats_indexesNotOptimal_serverName_databaseName_tableName_indexNumber	U 	databaseName	2
deepSQLStats_indexesNotOptimal	ix_deepSQLStats_indexesNotOptimal_serverName_databaseName_tableName_indexNumber	U 	tableName	3
deepSQLStats_indexesNotOptimal	ix_deepSQLStats_indexesNotOptimal_serverName_databaseName_tableName_indexNumber	U 	indexNumber	4
dm_performanceCounters	ix_dm_performanceCounters	U 	ukey	1
dm_performanceCounters	ix_dm_performanceCounters	U 	counterName	2
dm_performanceObjects	ix_dm_performanceObjects	U 	ukey	1
dm_performanceObjects	ix_dm_performanceObjects	U 	objectName	2
dm_serverGroups	ix_dm_serverGroups_groupName	U 	groupName	1
dm_serverGroups	ix_dm_serverGroups_groupName	U 	isProduction	2
dm_serverGroups	ix_dm_serverGroups_groupName	U 	ukey	3
dm_serverGroups	ix_serverGroups_ukey	U 	ukey	1
dm_serverGroups	PK_dm_serverGroups	U 	ukey	1
dm_servers	ix_dm_servers_serverName	U 	serverName	1
dm_servers	ix_dm_servers_serverName	U 	ukey	2
dm_servers	ix_dm_servers_serverName	U 	isEnabled	3
dm_servers	ix_servers_serverName	U 	serverName	1
dm_servers	ix_servers_serverName	U 	ukey	2
dm_servers	ix_servers_serverName	U 	isEnabled	3
dm_servers	ix_servers_ukeyGroup	U 	ukey_group	1
dm_servers	ix_servers_ukeyGroup	U 	serverName	2
dm_servers	ix_servers_ukeyGroup	U 	ukey	3
dm_servers	PK_notificationLog_servers	U 	ukey	1
dm_settings	ix_dm_settings_settingName	U 	settingName	1
dm_settings	ix_dm_settings_settingName	U 	ukey	2
eventLog	ix_eventLog_computerName	U 	computerName	1
eventLog	ix_eventLog_computerName	U 	timeWritten	2
eventLog	ix_eventLog_computerName	U 	data_timestamp	3
eventLog	ix_eventLog_computerName	U 	ukey	4
eventLog	ix_eventLog_dataTimestamp	U 	data_timestamp	1
eventLog	ix_eventLog_dataTimestamp	U 	computerName	2
eventLog	ix_eventLog_timeWritten	U 	timeWritten	1
eventLog	ix_eventLog_timeWritten	U 	computerName	2
eventLog	ix_eventLog_ukey	U 	ukey	1
eventLog	ix_eventLog_ukey	U 	computerName	2
eventlog_history	ix_eventLogHistory_ukeyGroup	U 	ukey_group	1
eventlog_history	ix_eventLogHistory_ukeyGroup	U 	ymd	2
eventlog_history	ix_eventLogHistory_ymd	U 	ymd	1
eventlog_history	ix_eventLogHistory_ymd	U 	ukey_group	2
eventlog_history	ix_eventLogHistory_ymd	U 	serverName	3
eventLog_stage	ix_eventLog_stage_computerName_message	U 	computerName	1
eventLog_stage	ix_eventLog_stage_computerName_message	U 	message	2
indexPerformanceLog	ix_indexPerformanceLog_serverName_databaseName_tableName_ymd	U 	serverName	1
indexPerformanceLog	ix_indexPerformanceLog_serverName_databaseName_tableName_ymd	U 	databaseName	2
indexPerformanceLog	ix_indexPerformanceLog_serverName_databaseName_tableName_ymd	U 	tableName	3
indexPerformanceLog	ix_indexPerformanceLog_serverName_databaseName_tableName_ymd	U 	ymd	4
indexPerformanceLog	ix_indexPerformanceLog_serverName_ymd	U 	serverName	1
indexPerformanceLog	ix_indexPerformanceLog_serverName_ymd	U 	ymd	2
messageRules	ix_messageRules_username	U 	userName	1
messageRules	ix_messageRules_username	U 	sendMessage	2
messageRules	ix_messageRules_username	U 	doNotSendMessage	3
messageRules	pk_messageRules_ukey	U 	ukey	1
notificationLog	ix_notificationLog_serverName	U 	serverName	1
notificationLog	ix_notificationLog_serverName	U 	ymd	2
notificationLog	ix_notificationLog_ymd	U 	ymd	1
notificationLog	ix_notificationLog_ymd	U 	serverName	2
notificationLog_stage	ix_notificationLogStage_serverName	U 	serverName	1
notificationLog_stage	ix_notificationLogStage_serverName	U 	ukey	2
notificationLog_stage	ix_notificationLogStage_serverName	U 	ymd	3
notificationLog_stage	ix_notificationLogStage_ukey	U 	ukey	1
notificationLog_stage	ix_notificationLogStage_ukey	U 	serverName	2
notificationLog_stage	ix_notificationLogStage_ukey	U 	ymd	3
notificationLog_stage	ix_notificationLogStage_ymd	U 	ymd	1
notificationLog_stage	ix_notificationLogStage_ymd	U 	serverName	2
notificationLog_stage	ix_notificationLogStage_ymd	U 	ukey	3
notificationsSent	ix_notificationsSent_compound	U 	ukey_notification	1
notificationsSent	ix_notificationsSent_compound	U 	userName	2
notificationsSent	ix_notificationsSent_compound	U 	emailAddress	3
performanceLog	ix_performanceLog_runStamp_server_object_counter_ukey	U 	runStamp	1
performanceLog	ix_performanceLog_runStamp_server_object_counter_ukey	U 	ukey_server	2
performanceLog	ix_performanceLog_runStamp_server_object_counter_ukey	U 	ukey_object	3
performanceLog	ix_performanceLog_runStamp_server_object_counter_ukey	U 	ukey_counter	4
performanceLog	ix_performanceLog_runStamp_server_object_counter_ukey	U 	ukey	5
performanceLog	ix_performanceLog_ukeyServer_ymd_runStamp	U 	ukey_server	1
performanceLog	ix_performanceLog_ukeyServer_ymd_runStamp	U 	ymd	2
performanceLog	ix_performanceLog_ukeyServer_ymd_runStamp	U 	runStamp	3
performanceLog_daily	ix_performanceLogDaily_compound	U 	ymd	1
performanceLog_daily	ix_performanceLogDaily_compound	U 	runStamp	2
performanceLog_stage	ix_performanceLog_stage_runStamp	U 	runStamp	1
pingLog	ix_pingLog_compound	U 	ymd	1
pingLog	ix_pingLog_compound	U 	serverName	2
pingLog	ix_pingLog_compound	U 	isServerPingable	3
processLog	ix_processLog_clustered	U 	ymd	1
processLog	ix_processLog_clustered	U 	serverName	2
processLog	ix_processLog_clustered	U 	spid	3
processLog	ix_processLog_clustered	U 	lastBatchTime	4
processLog	ix_processLog_clustered	U 	command	5
processLog	ix_processLog_serverName	U 	serverName	1
processLog	ix_processLog_serverName	U 	ymd	2
processLog	ix_processLog_serverName	U 	hostname	3
processLog	ix_processLog_serverName	U 	spid	4
processLog	ix_processLog_serverName	U 	login_time	5
processLog	ix_processLog_serverName	U 	programName	6
processLog	ix_processLog_serverName	U 	lastBatchTime	7
processLog	ix_processLog_serverName	U 	cputime	8
processLog	ix_processLog_serverName	U 	diskio	9
processLog	ix_processLog_serverName_unique	U 	ymd	1
processLog	ix_processLog_serverName_unique	U 	serverName	2
processLog	ix_processLog_serverName_unique	U 	spid	3
processLog	ix_processLog_serverName_unique	U 	dbName	4
processLog	ix_processLog_serverName_unique	U 	login	5
processLog	ix_processLog_serverName_unique	U 	hostname	6
queue_messages_1977058079	queue_clustered_index	IT	status	1
queue_messages_1977058079	queue_clustered_index	IT	conversation_group_id	2
queue_messages_1977058079	queue_clustered_index	IT	conversation_handle	3
queue_messages_1977058079	queue_clustered_index	IT	queuing_order	4
queue_messages_1977058079	queue_secondary_index	IT	status	1
queue_messages_1977058079	queue_secondary_index	IT	priority	2
queue_messages_1977058079	queue_secondary_index	IT	queuing_order	3
queue_messages_1977058079	queue_secondary_index	IT	conversation_group_id	4
queue_messages_1977058079	queue_secondary_index	IT	conversation_handle	5
queue_messages_1977058079	queue_secondary_index	IT	service_id	6
queue_messages_2009058193	queue_clustered_index	IT	status	1
queue_messages_2009058193	queue_clustered_index	IT	conversation_group_id	2
queue_messages_2009058193	queue_clustered_index	IT	conversation_handle	3
queue_messages_2009058193	queue_clustered_index	IT	queuing_order	4
queue_messages_2009058193	queue_secondary_index	IT	status	1
queue_messages_2009058193	queue_secondary_index	IT	priority	2
queue_messages_2009058193	queue_secondary_index	IT	queuing_order	3
queue_messages_2009058193	queue_secondary_index	IT	conversation_group_id	4
queue_messages_2009058193	queue_secondary_index	IT	conversation_handle	5
queue_messages_2009058193	queue_secondary_index	IT	service_id	6
queue_messages_2041058307	queue_clustered_index	IT	status	1
queue_messages_2041058307	queue_clustered_index	IT	conversation_group_id	2
queue_messages_2041058307	queue_clustered_index	IT	conversation_handle	3
queue_messages_2041058307	queue_clustered_index	IT	queuing_order	4
queue_messages_2041058307	queue_secondary_index	IT	status	1
queue_messages_2041058307	queue_secondary_index	IT	priority	2
queue_messages_2041058307	queue_secondary_index	IT	queuing_order	3
queue_messages_2041058307	queue_secondary_index	IT	conversation_group_id	4
queue_messages_2041058307	queue_secondary_index	IT	conversation_handle	5
queue_messages_2041058307	queue_secondary_index	IT	service_id	6
serviceLog	ix_serviceLog_compound	U 	ukey_run	1
serviceLog	ix_serviceLog_compound	U 	serverName	2
serviceLog	ix_serviceLog_compound	U 	ukey	3
tableSizeLog	ix_tableSizeLog_serverName_tableName_ymd	U 	serverName	1
tableSizeLog	ix_tableSizeLog_serverName_tableName_ymd	U 	tableName	2
tableSizeLog	ix_tableSizeLog_serverName_tableName_ymd	U 	ymd	3
tableSizeLog	ix_tableSizeLog_serverName_ymd	U 	serverName	1
tableSizeLog	ix_tableSizeLog_serverName_ymd	U 	ymd	2
userEmails	PK__userEmails__117F9D94	U 	ukey	1
GO
