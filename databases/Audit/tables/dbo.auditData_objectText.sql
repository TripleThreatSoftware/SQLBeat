alter table auditData_objectText add ymd_firstSeen dateTime default getDate()
alter table auditData_objectText add ymd_lastSeen dateTime default getDate()
alter table auditData_objectText add isCurrent bit default 1
GO
truncate table auditData_objectText
GO
alter table auditData_objectText drop column ymd
GO
alter table auditData_objectText drop column ukey_auditRun
GO
