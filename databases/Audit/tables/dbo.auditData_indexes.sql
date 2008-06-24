create table auditData_indexes (ukey int identity, ukey_auditRun bigint, ymd dateTime default getDate(), serverName varchar(200),
	databaseName varchar(500), tableName varchar(500), tableID bigint,
	indexID bigint, indexName varchar(200), indexXType varchar(2), columnName varchar(200), keyNumber int)
GO
