create table auditData_tableStructure (ukey int identity, ukey_auditRun bigint, ymd dateTime default getDate(), serverName varchar(200),
	databaseName varchar(500), tableName varchar(500), tableID bigint,
	xtype varchar(2), columnName varchar(200), columnLength smallint, columnPrecision tinyint, columnType tinyint,
	columnXType tinyint, columnIsNullable int)
GO
