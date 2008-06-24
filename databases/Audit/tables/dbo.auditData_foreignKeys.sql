create table auditData_foreignKeys (ukey int identity, ukey_auditRun bigint, ymd dateTime default getDate(), serverName varchar(200),
	databaseName varchar(500), id bigint, keyName varchar(200))
GO
update notification..dm_servers set lastObjectCheck = ''
GO
truncate table auditData_objectText
truncate table auditData_tableStructure
truncate table auditData_indexes
truncate table auditData_foreignKeys
GO
