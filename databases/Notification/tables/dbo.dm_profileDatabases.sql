create table dm_profileDatabases (ukey int identity, ymd dateTime default getDate(), ukey_profile int, ukey_server int, databaseName varchar(200))
GO
