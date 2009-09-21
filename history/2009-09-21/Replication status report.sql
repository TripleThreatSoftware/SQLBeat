declare @cPublisherServer varchar(500)
declare @cSubscriberServer varchar(500)

declare @cPublisherDatabase varchar(500)
declare @cSubscriberDatabase varchar(500)

declare @cSQLString nvarchar(4000)


set @cPublisherServer = '[dev01\sqlbeat2005]'
set @cSubscriberServer = '[dev01\sqlbeatDEMO]'

set @cPublisherDatabase = 'notification'
set @cSubscriberDatabase = 'notification'

set nocount on


-- tables that hold the golden copy
create table #objectText_remote (databaseName varchar(500), objectName varchar(500), tableName varchar(200), fieldName varchar(200), id bigint, xtype varchar(2), objectText varchar(8000), colid int)
create table #tableStructure_remote (databaseName varchar(500), tableName varchar(500), tableID bigint,
	xtype varchar(2), columnName varchar(200), columnLength smallint, columnPrecision tinyint, columnType tinyint,
	columnXType tinyint, columnIsNullable int)
create table #indexes_remote (databaseName varchar(500), tableName varchar(500), tableID bigint,
	indexID bigint, indexName varchar(200), indexXType varchar(2), columnName varchar(200),
	keyNumber int)


-- tables that hold the local copy
create table #objectText (databaseName varchar(500), objectName varchar(500), tableName varchar(200), fieldName varchar(200), id bigint, xtype varchar(2), objectText varchar(8000), colid int)
create table #tableStructure (databaseName varchar(500), tableName varchar(500), tableID bigint,
	xtype varchar(2), columnName varchar(200), columnLength smallint, columnPrecision tinyint, columnType tinyint,
	columnXType tinyint, columnIsNullable int)
create table #indexes (databaseName varchar(500), tableName varchar(500), tableID bigint,
	indexID bigint, indexName varchar(200), indexXType varchar(2), columnName varchar(200),
	keyNumber int)


--********************************************************************************************************************
--********************************************************************************************************************
-- Grab text of stored procedures
set @cSQLString = '
select
	''' + @cSubscriberDatabase + ''' as databaseName,
	isnull(c.name, '''') as tableName,
	isnull(d.name, '''') as fieldName,
	a.name as objectName,
	a.id, a.xtype,
	b.text as text, b.colID
	from [' + @cSubscriberServer + '].[' + @cSubscriberDatabase + '].dbo.sysobjects a
	join [' + @cSubscriberServer + '].[' + @cSubscriberDatabase + '].dbo.syscomments b on a.id = b.id
	left outer join [' + @cSubscriberServer + '].[' + @cSubscriberDatabase + '].dbo.sysobjects c on a.parent_obj = c.id
	left outer join [' + @cSubscriberServer + '].[' + @cSubscriberDatabase + '].dbo.syscolumns d on c.id = d.id
		and a.id = d.cdefault
	where a.xtype <> ''s''
		and left(a.name, 3) <> ''dt_''
		and a.name not like ''sys%''
		and a.name not like ''df__sys%''
		and a.name not like ''sp_%''
		and a.name not like ''df__MS%''
		and a.name not like ''syncobj%'''

-- grab what we currently have
insert into #objectText_remote (databaseName, tableName, fieldName, objectName, id, xtype, objectText, colid)
exec sp_executeSQL @cSQLString


--********************************************************************************************************************
--********************************************************************************************************************
-- Grab table structure

insert into #tableStructure_remote (databaseName, tableName, tableID, xtype, columnName, columnLength, columnPrecision, columnType, columnXType, columnIsNullable)
select
	'Notification' as databaseName,
	a.name, a.id, a.xtype, e.[name], e.length, e.xprec, e.type, e.xtype, e.isnullable
	from notification_gold.dbo.sysobjects a
	join notification_gold.dbo.syscolumns e on a.id = e.id
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and e.name <> space(0)
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'sys%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'mssnapshot%'
		and a.name not like 'mssubscription%'
		and a.name not like 'sp_ms%'
union
select
	'Audit' as databaseName,
	a.name, a.id, a.xtype, e.[name], e.length, e.xprec, e.type, e.xtype, e.isnullable
	from audit_gold.dbo.sysobjects a
	join audit_gold.dbo.syscolumns e on a.id = e.id
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and e.name <> space(0)
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'sys%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'mssnapshot%'
		and a.name not like 'mssubscription%'
		and a.name not like 'sp_ms%'
union
select
	'Configuration' as databaseName,
	a.name, a.id, a.xtype, e.[name], e.length, e.xprec, e.type, e.xtype, e.isnullable
	from Configuration_gold.dbo.sysobjects a
	join Configuration_gold.dbo.syscolumns e on a.id = e.id
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and e.name <> space(0)
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'sys%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'mssnapshot%'
		and a.name not like 'mssubscription%'
		and a.name not like 'sp_ms%'


insert into #indexes_remote (databaseName, tableName, tableID, indexID, indexName, indexXType, columnName, keyNumber)
select
	'Notification' as databaseName,
	a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
	from notification_gold.dbo.sysobjects a
	join notification_gold.dbo.sysindexes c on a.id = c.id
	join notification_gold.dbo.sysindexkeys d on a.id = d.id
		and c.indid = d.indid
	join notification_gold.dbo.syscolumns e on a.id = e.id
		and (d.colid = e.colid or d.id is null)
	where a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'ssnapshot%'
		and a.name not like 'mssubscription%'
		and c.name not like '%_dta_%'
union
select
	'Audit' as databaseName,
	a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
	from Audit_gold.dbo.sysobjects a
	join Audit_gold.dbo.sysindexes c on a.id = c.id
	join Audit_gold.dbo.sysindexkeys d on a.id = d.id
		and c.indid = d.indid
	join Audit_gold.dbo.syscolumns e on a.id = e.id
		and (d.colid = e.colid or d.id is null)
	where a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'ssnapshot%'
		and a.name not like 'mssubscription%'
		and c.name not like '%_dta_%'
union
select
	'Configuration' as databaseName,
	a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
	from Configuration_gold.dbo.sysobjects a
	join Configuration_gold.dbo.sysindexes c on a.id = c.id
	join Configuration_gold.dbo.sysindexkeys d on a.id = d.id
		and c.indid = d.indid
	join Configuration_gold.dbo.syscolumns e on a.id = e.id
		and (d.colid = e.colid or d.id is null)
	where a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'ssnapshot%'
		and a.name not like 'mssubscription%'
		and c.name not like '%_dta_%'

insert into #jobsteps_remote (job_name, enabled, step_id, step_name, subsystem, command, on_success_action, on_fail_action, database_name)
select
	a.name as job_name,
	a.enabled as enabled,
	b.step_id,
	b.step_name,
	b.subsystem,
	b.command,
	b.on_success_action,
	b.on_fail_action,
	b.database_name
	from msdb_gold.dbo.sysjobs a
	join msdb_gold.dbo.sysjobsteps b on a.job_id = b.job_id





-- grab what we currently have
insert into #objectText (databaseName, tableName, fieldName, objectName, id, xtype, objectText, colid)
select
	'Notification' as databaseName,
	isnull(c.name, '') as tableName,
	isnull(d.name, '') as fieldName,
	a.name as objectName,
	a.id, a.xtype,
	b.text as text, b.colID
	from notification.dbo.sysobjects a
	join notification.dbo.syscomments b on a.id = b.id
	left outer join notification.dbo.sysobjects c on a.parent_obj = c.id
	left outer join notification.dbo.syscolumns d on c.id = d.id
		and a.id = d.cdefault
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'sp_%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
union
select
	'Audit' as databaseName,
	isnull(c.name, '') as tableName,
	isnull(d.name, '') as fieldName,
	a.name as objectName,
	a.id, a.xtype,
	b.text as text, b.colID
	from audit.dbo.sysobjects a
	join audit.dbo.syscomments b on a.id = b.id
	left outer join audit.dbo.sysobjects c on a.parent_obj = c.id
	left outer join audit.dbo.syscolumns d on c.id = d.id
		and a.id = d.cdefault
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'sp_%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
union
select
	'Configuration' as databaseName,
	isnull(c.name, '') as tableName,
	isnull(d.name, '') as fieldName,
	a.name as objectName,
	a.id, a.xtype,
	b.text as text, b.colID
	from Configuration.dbo.sysobjects a
	join Configuration.dbo.syscomments b on a.id = b.id
	left outer join Configuration.dbo.sysobjects c on a.parent_obj = c.id
	left outer join Configuration.dbo.syscolumns d on c.id = d.id
		and a.id = d.cdefault
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'sp_%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'

insert into #tableStructure (databaseName, tableName, tableID, xtype, columnName, columnLength, columnPrecision, columnType, columnXType, columnIsNullable)
select
	'Notification' as databaseName,
	a.name, a.id, a.xtype, e.[name], e.length, e.xprec, e.type, e.xtype, e.isnullable
	from notification.dbo.sysobjects a
	join notification.dbo.syscolumns e on a.id = e.id
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and e.name <> space(0)
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'sys%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'mssnapshot%'
		and a.name not like 'mssubscription%'
		and a.name not like 'sp_ms%'
union
select
	'Audit' as databaseName,
	a.name, a.id, a.xtype, e.[name], e.length, e.xprec, e.type, e.xtype, e.isnullable
	from audit.dbo.sysobjects a
	join audit.dbo.syscolumns e on a.id = e.id
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and e.name <> space(0)
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'sys%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'mssnapshot%'
		and a.name not like 'mssubscription%'
		and a.name not like 'sp_ms%'
union
select
	'Configuration' as databaseName,
	a.name, a.id, a.xtype, e.[name], e.length, e.xprec, e.type, e.xtype, e.isnullable
	from Configuration.dbo.sysobjects a
	join Configuration.dbo.syscolumns e on a.id = e.id
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and e.name <> space(0)
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'sys%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'mssnapshot%'
		and a.name not like 'mssubscription%'
		and a.name not like 'sp_ms%'


insert into #indexes (databaseName, tableName, tableID, indexID, indexName, indexXType, columnName, keyNumber)
select
	'Notification' as databaseName,
	a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
	from notification.dbo.sysobjects a
	join notification.dbo.sysindexes c on a.id = c.id
	join notification.dbo.sysindexkeys d on a.id = d.id
		and c.indid = d.indid
	join notification.dbo.syscolumns e on a.id = e.id
		and (d.colid = e.colid or d.id is null)
	where a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'ssnapshot%'
		and a.name not like 'mssubscription%'
		and c.name not like '%_dta_%'
union
select
	'Audit' as databaseName,
	a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
	from Audit.dbo.sysobjects a
	join Audit.dbo.sysindexes c on a.id = c.id
	join Audit.dbo.sysindexkeys d on a.id = d.id
		and c.indid = d.indid
	join Audit.dbo.syscolumns e on a.id = e.id
		and (d.colid = e.colid or d.id is null)
	where a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'ssnapshot%'
		and a.name not like 'mssubscription%'
		and c.name not like '%_dta_%'
union
select
	'Configuration' as databaseName,
	a.name, a.id, c.indid, c.name, a.xtype, e.[name], d.keyno
	from Configuration.dbo.sysobjects a
	join Configuration.dbo.sysindexes c on a.id = c.id
	join Configuration.dbo.sysindexkeys d on a.id = d.id
		and c.indid = d.indid
	join Configuration.dbo.syscolumns e on a.id = e.id
		and (d.colid = e.colid or d.id is null)
	where a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'
		and a.name not like 'msreplication%'
		and a.name not like 'mspeer%'
		and a.name not like 'mspub%'
		and a.name not like 'ssnapshot%'
		and a.name not like 'mssubscription%'
		and c.name not like '%_dta_%'

insert into #jobsteps (job_name, enabled, step_id, step_name, subsystem, command, on_success_action, on_fail_action, database_name)
select
	a.name as job_name,
	a.enabled as enabled,
	b.step_id,
	b.step_name,
	b.subsystem,
	b.command,
	b.on_success_action,
	b.on_fail_action,
	b.database_name
	from msdb.dbo.sysjobs a
	join msdb.dbo.sysjobsteps b on a.job_id = b.job_id


delete from #jobSteps
	where job_name like 'EventLog Check %'
		or job_name like 'Configuration Check %'
		or job_name like 'SQL Detailed Check %'
		or job_name like 'SQL Fragmentation Check %'
		or job_name like 'Ping Check %'
		or job_name like 'SQL Integrity Check %'
		or job_name like 'SQL Service Check %'
		or job_name like 'Discovery%'
		or job_name like '%backup%'

delete from #jobSteps_remote
	where job_name like 'EventLog Check %'
		or job_name like 'Configuration Check %'
		or job_name like 'SQL Detailed Check %'
		or job_name like 'SQL Fragmentation Check %'
		or job_name like 'Ping Check %'
		or job_name like 'SQL Integrity Check %'
		or job_name like 'SQL Service Check %'
		or job_name like 'Discovery%'
		or job_name like '%backup%'

delete from #objectText
	where objectName like '%temp%'
		or objectName like '%tmp%'
		or objectName like 'v%_all'

delete from #objectText_remote
	where objectName like '%temp%'
		or objectName like '%tmp%'
		or objectName like 'v%_all'

delete from #tableStructure
	where tableName like 'v%_all'
		or tableName like 'filestream%'

delete from #tableStructure_remote
	where tableName like 'v%_all'
		or tableName like 'filestream%'

delete from #indexes
	where tableName like 'filestream%'

delete from #indexes_remote
	where tableName like 'filestream%'


--****************************************************************************************************************
--****************************************************************************************************************

select 'The following objects need to be synchronized'

select distinct a.databaseName, a.tableName, a.fieldName, a.objectName
	from (
		-- find things that are here but not in the golden copy
		select a.*
			from #objectText a
			left outer join #objectText_remote b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and a.colID = b.colID
				and (
					(
						a.xtype = 'D'
						and isnull(a.tableName, '') = isnull(b.tableName, '')
						and isnull(a.fieldName, '') = isnull(b.fieldName, '')
						and notification.dbo.fn_removeFormatting(a.objectText) = notification.dbo.fn_removeFormatting(b.objectText)
						)
					or (
						a.xtype <> 'D'
						and isnull(a.objectName, '') = isnull(b.objectName, '')
						and isnull(a.xtype, '') = isnull(b.xtype, '')
						and notification.dbo.fn_removeFormatting(a.objectText) = notification.dbo.fn_removeFormatting(b.objectText)
						)
					)
			where b.databaseName is null
		union
		-- find things that are in the golden copy but not here
		select a.*
			from #objectText_remote a
			left outer join #objectText b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
						and a.colID = b.colID
				and (
					(
						a.xtype = 'D'
						and isnull(a.tableName, '') = isnull(b.tableName, '')
						and isnull(a.fieldName, '') = isnull(b.fieldName, '')
						and notification.dbo.fn_removeFormatting(a.objectText) = notification.dbo.fn_removeFormatting(b.objectText)
						)
					or (
						a.xtype <> 'D'
						and isnull(a.objectName, '') = isnull(b.objectName, '')
						and isnull(a.xtype, '') = isnull(b.xtype, '')
						and notification.dbo.fn_removeFormatting(a.objectText) = notification.dbo.fn_removeFormatting(b.objectText)
						)
					)
			where b.databaseName is null
		) a
	order by a.databaseName, a.tableName, a.fieldname, a.objectName


--***************************************************************************************************************************
--***************************************************************************************************************************

select 'The following table objects need to be synchronized'

select distinct a.databaseName, a.tableName, a.columnName --, a.action
	from (
		-- find things that are here but not in the golden copy
		select a.* --, 'REMOVE' as action
			from #tableStructure a
			left outer join #tableStructure_remote b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
				and isnull(a.xtype, '') = isnull(b.xtype, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.columnLength, '') = isnull(b.columnLength, '')
				and isnull(a.columnPrecision, '') = isnull(b.columnPrecision, '')
				and isnull(a.columnType, '') = isnull(b.columnType, '')
				and isnull(a.columnXType, '') = isnull(b.columnXType, '')
				and isnull(a.columnIsNullable, '') = isnull(b.columnIsNullable, '')
			where b.databaseName is null
		union
		-- find things that are in the golden copy but not here
		select a.* --, 'ADD/CHANGE' as action
			from #tableStructure_remote a
			left outer join #tableStructure b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
				and isnull(a.xtype, '') = isnull(b.xtype, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.columnLength, '') = isnull(b.columnLength, '')
				and isnull(a.columnPrecision, '') = isnull(b.columnPrecision, '')
				and isnull(a.columnType, '') = isnull(b.columnType, '')
				and isnull(a.columnXType, '') = isnull(b.columnXType, '')
				and isnull(a.columnIsNullable, '') = isnull(b.columnIsNullable, '')
			where b.databaseName is null
		) a
	order by a.databaseName, a.tableName, a.columnName


--***************************************************************************************************************************
--***************************************************************************************************************************
-- deal with the indexes table

select 'The following indexes need to be synchronized'

-- find things that are here but not in the golden copy
select distinct databaseName, tableName, indexID, indexName, columnName --, a.action
	from (
		select a.* --, 'REMOVE' as action
			from #indexes a
			left outer join #indexes_remote b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
--				and isnull(a.indexID, '') = isnull(b.indexID, '')
				and isnull(a.indexName, '') = isnull(b.indexName, '')
				and isnull(a.indexXType, '') = isnull(b.indexXType, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.keyNumber, '') = isnull(b.keyNumber, '')
			where b.databaseName is null
		union
		-- find things that are in the golden copy but not here
		select a.* --, 'ADD/CHANGE' as action
			from #indexes_remote a
			left outer join #indexes b on isnull(a.databaseName, '') = isnull(b.databaseName, '')
				and isnull(a.tableName, '') = isnull(b.tableName, '')
--				and isnull(a.indexID, '') = isnull(b.indexID, '')
				and isnull(a.indexName, '') = isnull(b.indexName, '')
				and isnull(a.indexXType, '') = isnull(b.indexXType, '')
				and isnull(a.columnName, '') = isnull(b.columnName, '')
				and isnull(a.keyNumber, '') = isnull(b.keyNumber, '')
			where b.databaseName is null
		) a
	order by databaseName, tableName, indexID, indexName, columnName


--***************************************************************************************************************************
--***************************************************************************************************************************
-- deal with the jobs table

select 'The following jobs need to be synchronized'

select distinct job_name --, a.action --, step_id, step_name
	from (
		-- find things that are here but not in the golden copy
		select a.* --, 'DROP/ADD' as action
			from #jobsteps a
			left outer join #jobsteps_remote b on isnull(a.job_name, '') = isnull(b.job_name, '')
				and isnull(a.step_name, '') = isnull(b.step_name, '')
				and isnull(a.subsystem, '') = isnull(b.subsystem, '')
				and isnull(a.command, '') = isnull(b.command, '')
				and isnull(a.database_name, '') = isnull(b.database_name, '')
				and isnull(a.enabled, 0) = isnull(b.enabled, 0)
				and isnull(a.step_id, 0) = isnull(b.step_id, 0)
				and isnull(a.on_success_action, 0) = isnull(b.on_success_action, 0)
				and isnull(a.on_fail_action, 0) = isnull(b.on_fail_action, 0)
			where b.job_name is null
		union
		-- find things that are in the golden copy but not here
		select a.* --, 'DROP/ADD' as action
			from #jobsteps_remote a
			left outer join #jobsteps b on isnull(a.job_name, '') = isnull(b.job_name, '')
				and isnull(a.step_name, '') = isnull(b.step_name, '')
				and isnull(a.subsystem, '') = isnull(b.subsystem, '')
				and isnull(a.command, '') = isnull(b.command, '')
				and isnull(a.database_name, '') = isnull(b.database_name, '')
				and isnull(a.enabled, 0) = isnull(b.enabled, 0)
				and isnull(a.step_id, 0) = isnull(b.step_id, 0)
				and isnull(a.on_success_action, 0) = isnull(b.on_success_action, 0)
				and isnull(a.on_fail_action, 0) = isnull(b.on_fail_action, 0)
			where b.job_name is null
		) a
	order by a.job_name --, step_id, a.step_name

go

drop table #objectText_remote
drop table #tableStructure_remote
drop table #indexes_remote
drop table #jobsteps_remote

go

drop table #objectText
drop table #tableStructure
drop table #indexes
drop table #jobsteps

go
