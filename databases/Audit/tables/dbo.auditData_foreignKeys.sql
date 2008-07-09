alter table auditData_foreignKeys add ymd_firstSeen dateTime default getDate()
alter table auditData_foreignKeys add ymd_lastSeen dateTime default getDate()
alter table auditData_foreignKeys add isCurrent bit default 1
GO
truncate table auditData_foreignKeys
GO
alter table auditData_foreignKeys drop column ymd
GO
alter table auditData_foreignKeys drop column ukey_auditRun
GO
update  notification..dm_servers
	set lastObjectCheck = ''
	where serverName = 'devmssql02'
GO
