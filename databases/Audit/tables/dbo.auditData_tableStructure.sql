alter table auditData_tableStructure add ymd_firstSeen dateTime default getDate()
alter table auditData_tableStructure add ymd_lastSeen dateTime default getDate()
alter table auditData_tableStructure add isCurrent bit default 1
GO
truncate table auditData_tableStructure
GO
alter table auditData_tableStructure drop column ymd
GO
alter table auditData_tableStructure drop column ukey_auditRun
GO
