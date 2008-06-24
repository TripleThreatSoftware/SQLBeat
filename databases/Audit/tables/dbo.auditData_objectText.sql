create table auditData_objectText (ukey int identity, ukey_auditRun bigint, ymd dateTime default getDate(), serverName varchar(200),
	databaseName varchar(500), objectName varchar(500), id bigint, xtype varchar(2), objectText varchar(8000))
GO
