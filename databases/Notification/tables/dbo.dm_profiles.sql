create table dm_profiles (ukey int identity, ymd dateTime default getDate(), profileName varchar(200), machineID varchar(100))
GO
