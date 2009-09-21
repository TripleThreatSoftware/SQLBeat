--***********************************************************************************************
--***********************************************************************************************
-- To run, simply select the database you'd like to have Replication dropped for and hit F5
--***********************************************************************************************
--***********************************************************************************************

-- get rid of the subscription articles first
declare @cSQLString nvarchar(4000)
set @cSQLString = ''

select
	@cSQLString = @cSQLString + 'exec sp_dropsubscription @publication = N''' + a.publication + ''', @article = N''all'', @subscriber = N''all'' '

	from [sqldist-ny].distribution.dbo.mspublications a
	where a.publisher_db = db_name()

if @cSQLString <> ''
begin
	print @cSQLString
	exec sp_executeSQL @cSQLString
end

go

-- get rid of the subscription articles first
-- then, get rid of the publication articles

declare @cSQLString nvarchar(4000)
declare @nUkey int

set @nUkey = 0

select
	distinct a.publication, b.article, identity(int) as ukey
	into #articles
	from [sqldist-ny].distribution.dbo.mspublications a
	join [sqldist-ny].distribution.dbo.msarticles b on a.publication_id = b.publication_id
		and a.publisher_db = b.publisher_db
	where a.publisher_db = db_name()

while exists (select top 1 ukey from #articles where ukey > @nUkey)
begin
	select top 1
		@nUkey = ukey,
		@cSQLString =
			'exec sp_dropsubscription @publication = N''' + publication + ''', @article = N''' + article + ''', @subscriber = N''all'', @destination_db = N''all'' ' +
			'exec sp_droparticle @publication = N''' + publication + ''', @article = N''' + article + ''', @force_invalidate_snapshot = 1 '
		from #articles
		where ukey > @nUkey
		order by ukey

	print @cSQLString
	exec sp_executeSQL @cSQLString
end


go

drop table #articles
go

-- last, get rid of the publication itself
declare @cSQLString nvarchar(4000)
set @cSQLString = ''

select @cSQLString = @cSQLString +
	'exec sp_droppublication @publication = N''' + a.publication + ''''
	from [sqldist-ny].distribution.dbo.mspublications a
	where a.publisher_db = db_name()

if @cSQLString <> ''
begin
	print @cSQLString
	exec sp_executeSQL @cSQLString
end
GO

if @@trancount > 0
	commit work

go

-- and, to be safe, get rid of all the replication flags

declare @cSQLString nvarchar(4000)
set @cSQLString = 'exec sp_replicationdboption ''' + db_name() + ''', ''publish'', false'

print @cSQLString
exec sp_executeSQL @cSQLString

go

declare @cSQLString nvarchar(4000)
set @cSQLString = 'exec sp_replicationdboption ''' + db_name() + ''', ''merge publish'', false'

print @cSQLString
exec sp_executeSQL @cSQLString

go

declare @cSQLString nvarchar(4000)
set @cSQLString = 'exec sp_removedbreplication ''' + db_name() + ''''

print @cSQLString
exec sp_executeSQL @cSQLString

go

if @@trancount > 0
	commit work
