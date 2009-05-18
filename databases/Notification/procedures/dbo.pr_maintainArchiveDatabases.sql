/****** Object:  StoredProcedure [dbo].[pr_maintainArchiveDatabases]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_maintainArchiveDatabases]
as
begin
	select
		[name],
		identity(int) as ukey
		into #archiveDatabases
		from master.dbo.sysdatabases (nolock)
		where [name] like '%notification%'
			and [name] <> 'notification'
		order by [name] desc

	declare @nThisUkey int
	declare @cSQLString nvarchar(4000)
	set @nThisUkey = 3

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
