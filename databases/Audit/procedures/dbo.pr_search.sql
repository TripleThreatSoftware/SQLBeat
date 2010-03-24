USE [Audit]
GO

/****** Object:  StoredProcedure [dbo].[pr_search]    Script Date: 03/24/2010 12:24:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- exec pr_search 'sqlcluster01', 'portalpro', 'test'
alter procedure [dbo].[pr_search] (@cServerName varchar(100) = '', @cDatabaseName varchar(100) = '', @cSearchString varchar(100))
as
begin
	set nocount on

	create table #results (ukey int identity, serverName varchar(100), databaseName varchar(200), objectName varchar(200), objectType varchar(100),
		objectText varchar(8000), colID int)

	if isnull(@cSearchString, '') <> ''
	begin
		insert into #results (serverName, databaseName, objectName, objectType, objectText, colID)
		select
			serverName, databaseName, objectName,
			CASE
				when xtype = 'C' then 'CHECK constraint'
				when xtype = 'D' then 'Default or DEFAULT constraint'
				when xtype = 'F' then 'FOREIGN KEY constraint'
				when xtype = 'L' then 'Log'
				when xtype = 'FN' then 'Scalar function'
				when xtype = 'IF' then 'Inlined table-function'
				when xtype = 'P' then 'Stored procedure'
				when xtype = 'PK' then 'PRIMARY KEY constraint (type is K)'
				when xtype = 'RF' then 'Replication filter stored procedure '
				when xtype = 'S' then 'System table'
				when xtype = 'TF' then 'Table function'
				when xtype = 'TR' then 'Trigger'
				when xtype = 'U' then 'User table'
				when xtype = 'UQ' then 'UNIQUE constraint (type is K)'
				when xtype = 'V' then 'View'
				when xtype = 'X' then 'Extended stored procedure'
				else 'Unknown'
			END AS objectType,
			replace(replace(replace(replace(objectText, '<', '_'), '>', '_'), @cSearchString, '<b>' + @cSearchString + '</b>'), char(9), '&nbsp;&nbsp;&nbsp;&nbsp;') as objectText,
			colID
			from auditdata_objectText a (nolock)
			where (a.serverName = @cServerName or isnull(@cServerName, '') = '')
				and (a.databaseName = @cDatabaseName or isnull(@cDatabaseName, '') in ('', 'All Databases'))
				and isCurrent = 1
				and (
					objectText like '%' + @cSearchString + '%'
					or objectName like '%' + @cSearchString + '%'
					)

		declare @nUkey int
		declare @cString varchar(8000)
		create table #code (ukey int, codeString varchar(8000))

		set @nUkey = 0
		while exists (select top 1 ukey from #results where ukey > @nUkey)
		begin
			select top 1 @nUkey = ukey, @cString = objectText from #results where ukey > @nUkey order by ukey

			truncate table #code
			insert into #code (ukey, codeString)
			select ukey, listItem
				from notification.dbo.fn_makeTableFromList(@cString, char(13))

			set @cString = ''
			select @cString = @cString + codeString + '<br>'
				from #code
				where ukey in (select ukey from #code where codeString like '%' + @cSearchString + '%')
					or (ukey - 1) in (select ukey from #code where codeString like '%' + @cSearchString + '%')
					or (ukey + 1) in (select ukey from #code where codeString like '%' + @cSearchString + '%')
				order by ukey

			update #results set objectText = @cString where ukey = @nUkey

		end
	end

	select distinct serverName, databaseName, objectName, objectText, objectType, colID
		from #results
		order by serverName, databaseName, objectName, colID

	drop table #results
end

GO
