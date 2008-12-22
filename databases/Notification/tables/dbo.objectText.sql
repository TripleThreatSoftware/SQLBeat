create table objectText (databaseName varchar(500), objectName varchar(500), tableName varchar(200), fieldName varchar(200), id bigint, xtype varchar(2), objectText varchar(max), colid int, ukey int identity)
create table tableStructure (databaseName varchar(500), tableName varchar(500), tableID bigint, xtype varchar(2), columnName varchar(200), columnLength smallint, columnPrecision tinyint, columnType tinyint, columnXType tinyint, columnIsNullable int)
create table indexes (databaseName varchar(500), tableName varchar(500), tableID bigint, indexID bigint, indexName varchar(200), indexXType varchar(2), columnName varchar(200), keyNumber int)
create table jobsteps (job_name varchar(500), enabled bit, step_id int, step_name varchar(500), subsystem varchar(100), command varchar(8000), on_success_action int, on_fail_action int, database_name varchar(200))
GO
truncate table objectText
truncate table tableStructure
truncate table indexes
truncate table jobSteps
GO
insert into objectText (databaseName, tableName, fieldName, objectName, id, xtype, objectText, colid)
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
	left outer join notification.dbo.syscolumns d on c.id = d.id
		and a.id = d.cdefault
	where a.xtype <> 's'
		and left(a.name, 3) <> 'dt_'
		and a.name not like 'sys%'
		and a.name not like 'df__sys%'
		and a.name not like 'sp_%'
		and a.name not like 'df__MS%'
		and a.name not like 'syncobj%'

insert into tableStructure (databaseName, tableName, tableID, xtype, columnName, columnLength, columnPrecision, columnType, columnXType, columnIsNullable)
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


insert into indexes (databaseName, tableName, tableID, indexID, indexName, indexXType, columnName, keyNumber)
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

insert into jobsteps
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




declare @cObjectName varchar(200)
declare @cDatabaseName varchar(200)
declare @nThisUkey int
declare @cThisLine varchar(max)
declare @nLine int
set @cObjectName = ''
set @cDatabaseName = ''
set @nThisUkey = 0

while exists (select top 1 objectName from objectText where colid <> 1 and ukey > @nThisUkey)
begin

	select top 1
		@cObjectName = objectName,
		@cDatabaseName = databaseName
		from objectText
		where colid <> 1
			and ukey > @nThisUkey
		order by ukey

	set @nLine = 0
	set @cThisLine = ''

	while exists (
		select top 1 colid
			from objectText
			where databaseName = @cDatabaseName
				and objectName = @cObjectName
				and colid > @nLine
		)
	begin
		select top 1
			@nLine = colid,
			@cThisLine = @cThisLine + objectText
			from objectText
			where databaseName = @cDatabaseName
				and objectName = @cObjectName
				and colid > @nLine
			order by colid
	end

	print 'Object: ' + @cObjectName
	print 'Text: ' + @cThisLine

	update objectText set objectText = @cThisLine where databaseName = @cDatabaseName and objectName = @cObjectName and colID = 1
	delete from objectText where databaseName = @cDatabaseName and objectName = @cObjectName and colID <> 1
end
GO
