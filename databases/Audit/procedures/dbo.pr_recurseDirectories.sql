/****** Object:  StoredProcedure [dbo].[pr_recurseDirectories]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_recurseDirectories '\\web02\C$\inetpub\logs\LogFiles'
-- exec pr_recurseDirectories 'C:\Temp\websites\BritishFasteners\BritishFasteners\www.example.com\index.php\products'
-- drop table #filesToImport
-- create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)
-- create clustered index ix_tmp_filesToImport_ukey on #filesToImport (ukey) with fillfactor = 60
CREATE procedure [dbo].[pr_recurseDirectories] (@cDirectory varchar(2000), @nDepth int = 0, @bRecurse bit = 1)
as
begin
	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cThisDirectory varchar(8000)
	declare @nUkey int
	declare @cFileName varchar(1000)
	declare @cGUID uniqueIdentifier

	declare @filesToImport table (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)

	if isnull(@nDepth, 0) = 0
		and not exists (select top 1 [name] from tempdb.dbo.sysobjects where [name] like '%filesToImport%')
	begin
		create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)
		create clustered index ix_tmp_filesToImport on #filesToImport (ukey) with fillfactor = 60
	end

	set @cGUID = newid()

	set @cSQLString = 'dir "' + @cDirectory + '"'

	print @cSQLString

	insert into @filesToImport (dirString)
	exec master..xp_cmdshell @cSQLString

--	print '  Added ' + convert(varchar(20), @@rowcount) + ' rows'

	delete from @filesToImport where dirString like '%exception%'

	set @cThisDirectory = ''

	update @filesToImport
		set
			--@cThisDirectory = directory = case
			--when dirString like '%directory of%' then substring(dirString, charindex('\', dirString) - 2, 500)
			--else @cThisDirectory end,
			fileDate = case when isDate(left(dirString, 22)) = 1 then convert(dateTime, left(dirString, 22)) else null end,
			fileSize = case
				when not dirString like '%<dir>%' and not dirString like '%volume in%' and not dirString like '%bytes free%' and not dirString like '%directory of%' and not dirString like '%file(s)%bytes%'
					then dbo.fn_returnDigits(left(ltrim(substring(dirString, 22, 99)), charindex(' ', ltrim(substring(dirString, 22, 99)))), 0) else 0 end,
			fileName = case
				when not dirString like '%<dir>%' and not dirString like '%volume in%' and not dirString like '%bytes free%' and not dirString like '%directory of%' and not dirString like '%file(s)%bytes%' then substring(dirString, 40, 8000)
				when dirString like '%<DIR>%' then rtrim(ltrim(substring(dirString, charindex('<DIR>', dirString) + 6, 500)))
				else null end,
			dirGUID = @cGUID,
			directory = @cDirectory,
			filePath = @cDirectory + '\' + case
				when not dirString like '%<dir>%' and not dirString like '%volume in%' and not dirString like '%bytes free%' and not dirString like '%directory of%' and not dirString like '%file(s)%bytes%' then substring(dirString, 40, 8000)
				when dirString like '%<DIR>%' then rtrim(ltrim(substring(dirString, charindex('<DIR>', dirString) + 6, 500)))
				else null end
		from @filesToImport

	delete
		from @filesToImport
		where (
				isnull(fileName, '') in ('', '.', '..')
				or isnull(directory, '') = ''
				)

--	print '  Deleted ' + convert(varchar(20), @@rowcount) + ' dud rows'

	insert into #filesToImport (dirString, fileName, directory, filePath, fileDate, fileSize, dirGUID)
	select dirString, fileName, directory, filePath, fileDate, fileSize, dirGUID from @filesToImport

	set @nUkey = 0
	set @nDepth = @nDepth + 1

	-- recurse into subdirectories
	while exists (select top 1 ukey from @filesToImport where ukey > @nUkey and dirString like '%<DIR>%' and isnull(filePath, '') <> '')
		and @bRecurse = 1
	begin

		select top 1
			@nUkey = ukey,
			@cThisDirectory = filePath
			from @filesToImport
			where ukey > @nUkey
				and dirString like '%<DIR>%'
				and isnull(filePath, '') <> ''
			order by ukey

		print 'Processing (' + convert(varchar(20), @nDepth) + '): ' + @cThisDirectory

		exec pr_recurseDirectories @cThisDirectory, @nDepth, @bRecurse
	end

	set @nDepth = @nDepth - 1

	--if @nDepth = 0
	--	select ukey, dirString, fileName, directory, filePath, fileDate, fileSize from #filesToImport
end
GO
