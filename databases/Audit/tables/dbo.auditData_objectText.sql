alter table auditData_objectText add textChecksum bigint default 0
GO
update auditData_objectText set textChecksum = notification.dbo.fn_checksum(isnull(objectText, ''))
GO
