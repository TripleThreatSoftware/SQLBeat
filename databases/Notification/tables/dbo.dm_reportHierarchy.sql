create table dm_reportHierarchy (ukey int identity, ymd dateTime default getDate(), ukey_parent int, ukey_child int)
create table dm_reports (ukey int identity, ymd dateTime default getDate(), reportName varchar(500), isCategory bit default 0, isGraphDisplay bit default 0, isGridDisplay bit default 0)
create table dm_reportParameters (ukey int identity, ukey_report int, ymd dateTime default getDate(), parameterType varchar(20), parameterName varchar(100), defaultValue varchar(100))
GO
