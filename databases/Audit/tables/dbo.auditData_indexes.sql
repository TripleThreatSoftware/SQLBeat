alter table auditData_indexes add ymd_firstSeen dateTime default getDate()
alter table auditData_indexes add ymd_lastSeen dateTime default getDate()
alter table auditData_indexes add isCurrent bit default 1
GO
truncate table auditData_indexes
GO
alter table auditData_indexes drop column ymd
GO
alter table auditData_indexes drop column ukey_auditRun
GO
