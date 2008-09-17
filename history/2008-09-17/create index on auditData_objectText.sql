use [audit]
go
create clustered index ix_objectText_serverName_databaseName_objectName on auditData_objectText (serverName, databaseName, objectName) with fillfactor = 70
