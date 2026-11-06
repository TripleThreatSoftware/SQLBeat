/****** Object:  StoredProcedure [dbo].[pr_maintainArchiveDatabases]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_maintainArchiveDatabases]
as
begin
	declare @nThisUkey int
	declare @cSQLString nvarchar(4000)

	select
		[name],
		identity(int) as ukey
		into #archiveDatabases
		from master.dbo.sysdatabases (nolock)
		where [name] like '%' + db_name() + '%'
			and [name] <> db_name()
		order by [name] desc

	set @nThisUkey = 12

	while exists (select top 1 [name] from #archiveDatabases where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@cSQLString = 'drop database [' + [name] + ']'
			from #archiveDatabases
			where ukey > @nThisUkey
			order by ukey

		print @cSQLString
		exec sp_executeSQL @cSQLString
	end

	drop table #archiveDatabases

	exec pr_maintainPartitionedViews
end
GO
