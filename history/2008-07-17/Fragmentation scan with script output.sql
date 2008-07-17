declare @lReportOnly bit
set @lReportOnly = 0

--*************************************************************************************************************************
-- No changes below this point
--*************************************************************************************************************************

set nocount on

declare @cSQLString nvarchar(4000)
declare @cThisDatabase varchar(200)

create table #scanResults (ukey int identity, dbName varchar(200),
	objectName varchar(200), objectID bigInt, indexName varchar(200), indexID int, level int, pages bigint, rows bigint,
	minimumRecordSize bigint, maximumRecordSize bigint, averageRecordSize decimal(20,3), forwardedRecords int, extents bigint,
	extentSwitches bigint, averageFreeBytes decimal(20,3), averagePageDensity decimal(20,15), scanDensity decimal(20,15),
	bestCount int, actualCount int, logicalFragmentation decimal(20,15), extentFragmentation decimal(20,15))

set @cSQLString = ''
set @cThisDatabase = ''
while exists (
	select top 1 [name]
		from master..sysdatabases
		where (status & 32) <> 32 -- loading
			and (status & 64) <> 64 -- prerecovery
			and (status & 128) <> 128 -- recovery
			and (status & 512) <> 512 -- offline
			and (status & 4096) <> 4096 -- single user
			and [name] > @cThisDatabase
			and [name] not in ('master', 'model', 'msdb', 'tempdb')

			and [name] like '%transactions%'
	)
begin
	select top 1 @cThisDatabase = [name]
		from master..sysdatabases
		where (status & 32) <> 32 -- loading
			and (status & 64) <> 64 -- prerecovery
			and (status & 128) <> 128 -- recovery
			and (status & 512) <> 512 -- offline
			and (status & 4096) <> 4096 -- single user
			and [name] > @cThisDatabase
			and [name] not in ('master', 'model', 'msdb', 'tempdb')
			and [name] like '%transactions%'
		order by [name]

	set @cSQLString =
		'use [' + @cThisDatabase + ']' + char(13) +
		'dbcc showcontig with tableResults'
--	print @cSQLString

	insert into #scanResults (objectName, objectID, indexName, indexID, level, pages, rows, minimumRecordSize,
			maximumRecordSize, averageRecordSize, forwardedRecords, extents, extentSwitches, averageFreeBytes, averagePageDensity,
			scanDensity, bestCount, actualCount, logicalFragmentation, extentFragmentation)
	exec sp_executeSQL @cSQLString

	update #scanResults
		set dbName = @cThisDatabase
		where dbName is null
end

select
*
	from #scanResults
	where isnull([rows], 0) > 10000
		and (
			convert(decimal(20,4), abs(extentSwitches - extents)) / convert(decimal(20,4), extents) > .15
			or scanDensity < 75
			)
	order by [rows] desc

if @lReportOnly = 0
begin
	select identity(int) as ukey, dbName, convert(varchar(100), space(0)) as objectOwner, objectName, indexName, [rows], extents, extentSwitches, scanDensity
		into #actions
		from #scanResults
		where isnull([rows], 0) > 10000
			and (
				convert(decimal(20,4), abs(extentSwitches - extents)) / convert(decimal(20,4), extents) > .15
				or scanDensity < 50
				)
			and objectname <> 'log'
		order by isnull([rows], 0) desc

	declare @nThisUkey int
	set @nThisUkey = 0

	while exists (select top 1 ukey from #actions where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@cSQLString =
				'use [' + dbName + ']' + char(13) +
				'if (select count(*) from sysobjects where [name] = ''' + objectName + ''' and xtype = ''SN'') = 0' + char(13) +
				'	and (select count(*) from sysobjects where [name] = ''' + objectName + ''' and xtype = ''U'') = 1' + char(13) +
				'begin' + char(13) +
				'	declare @cOwner varchar(100)' + char(13) +
				'	declare @cObject varchar(200)' + char(13) +
				'	declare @cSQLString nvarchar(4000)' + char(13) +
				'	if @@version like ''%sql server 2005%'' and @@version like ''%enterprise%''' + char(13) +
				'	begin' + char(13) +
				'		set @cOwner = (select top 1 table_schema from information_schema.tables where table_name = ''' + objectName + ''')' + char(13) +
				'	end' + char(13) +
				'	else' + char(13) +
				'	begin' + char(13) +
				'		set @cOwner = (select top 1 user_name(uid) from sysobjects where [name] = ''' + objectName + ''' and xtype = ''U'')' + char(13) +
				'	end ' + char(13) +
				'	set @cObject = ''['' + @cOwner + ''].['' + ''' + objectName + ']''' + char(13) +
				'	set @cSQLString = ''' +
						case
							when @@version like '%sql server 2005%' and @@version like '%enterprise%'
								then '	alter index all on '' + @cObject + '' REBUILD WITH (ONLINE = ON)'
								else '	dbcc dbreindex('' + @cObject + ''' + case when isnull(indexName, '') <> '' then ', ''''' + indexName + ''''', 0' else '''''' end + ')'
						end + '''' + char(13) +
				'	print @cSQLString' + char(13) +
				'--	exec sp_executeSQL @cSQLString' + char(13) +
				'end'
			from #actions
			where ukey > @nThisUkey
			order by ukey

--		print @cSQLString
		exec sp_executeSQL @cSQLString
	end

	drop table #actions
end

go

--drop table #scanResults

select * from #scanResults
