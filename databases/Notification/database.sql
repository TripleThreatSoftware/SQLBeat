declare @cSQLString nvarchar(4000)
set @cSQLString = ''

select
	@cSQLString = @cSQLString + char(13) + 'alter table [' + object_name(parent_obj) + '] drop constraint [' + [name] + ']'
	from (
		select distinct a.parent_obj, a.[name]
			from sysobjects a
			join sysconstraints b on a.id = b.constid
			join syscolumns c on b.colID = c.colID
				and c.[name] in ('ymd')
			where object_name(a.parent_obj) in ('auditData_objectText', 'auditData_tableStructure', 'auditData_indexes', 'auditData_foreignKeys')
				and a.xtype = 'D'
		) a

print @cSQLString
exec (@cSQLString)
GO
drop index auditData_objectText.ix_objectText_serverName_databaseName_objectName_auditRun
GO
drop index auditData_objectText.ix_objectText_serverName_auditRun
GO
drop index auditData_objectText.ix_objectText_ymd_auditRun_serverName
GO
