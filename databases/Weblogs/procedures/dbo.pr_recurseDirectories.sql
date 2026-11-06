/****** Object:  StoredProcedure [dbo].[pr_recurseDirectories]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_recurseDirectories 'C:\Temp\san antonio\aprilia'
-- exec pr_recurseDirectories 'C:\Temp\websites\BritishFasteners\BritishFasteners\www.example.com\index.php\products'
-- drop table #filesToImport
-- create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)
-- create clustered index ix_tmp_filesToImport_ukey on #filesToImport (ukey) with fillfactor = 60
CREATE procedure [dbo].[pr_recurseDirectories] (@cDirectory varchar(2000), @nDepth int = 0)
as
begin
	set nocount on

	if @nDepth = 0 and not exists (select top 1 [name] from tempdb.dbo.sysobjects where [name] like '%filesToImport%')
	begin
		create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)
		create clustered index ix_tmp_filesToImport on #filesToImport (ukey) with fillfactor = 60
	end

	declare @cSQLString nvarchar(4000)
	declare @cThisDirectory varchar(8000)
	declare @nUkey int
	declare @cFileName varchar(1000)
	declare @cGUID uniqueIdentifier

	set @cGUID = newid()

	set @cSQLString = 'dir "' + @cDirectory + '"'

	print @cSQLString

	insert into #filesToImport (dirString)
	exec master..xp_cmdshell @cSQLString

	print '  Added ' + convert(varchar(20), @@rowcount) + ' rows'

	update #filesToImport set dirGUID = @cGUID, directory = @cDirectory where dirGUID is null

	set @cThisDirectory = ''

	--update #filesToImport
	--	set @cThisDirectory = directory = case
	--		when dirString like '%directory of%' then substring(dirString, charindex('\', dirString) - 2, 500)
	--		else @cThisDirectory end,
	--		fileName = dirString
	--	where dirGUID = @cGUID



	update #filesToImport
		set
			--@cThisDirectory = directory = case
			--when dirString like '%directory of%' then substring(dirString, charindex('\', dirString) - 2, 500)
			--else @cThisDirectory end,
			fileDate = case when isDate(left(dirString, 22)) = 1 then convert(dateTime, left(dirString, 22)) else null end,
			fileSize = case when isnumeric(left(dirstring, 1)) = 1
				then dbo.fn_returnDigits(left(ltrim(substring(dirString, 22, 99)), charindex(' ', ltrim(substring(dirString, 22, 99)))), 0) else 0 end,
			fileName = case
				when dirString like '%.csv%' then substring(dirString, 40, 8000)
				when dirString like '%.mp3%' then substring(dirString, 40, 8000)
				when dirString like '%.mp4%' then substring(dirString, 40, 8000)
				when dirString like '%.cvs%' then substring(dirString, 40, 8000)
				when dirString like '%.jpg%' then substring(dirString, 40, 8000)
				when dirString like '%.png%' then substring(dirString, 40, 8000)
				when dirString like '%.tif%' then substring(dirString, 40, 8000)
				when dirString like '%.htm%' then substring(dirString, 40, 8000)
				when dirString like '%.xml%' then substring(dirString, 40, 8000)
				when dirString like '%.svg%' then substring(dirString, 40, 8000)
				when dirString like '%.pdf%' then substring(dirString, 40, 8000)
--				when dirString like '%.htm%' then rtrim(ltrim(right(rtrim(ltrim(dirString)), charindex(' ', reverse(rtrim(ltrim(dirString)))))))
				when dirString like '%<DIR>%' then rtrim(ltrim(substring(dirString, charindex('<DIR>', dirString) + 6, 500)))
				when isnumeric(left(dirstring, 1)) = 1 then rtrim(ltrim(right(dirString, charindex(' ', reverse(dirstring)))))
				else null end
		from #filesToImport
		where dirGUID = @cGUID

--select * from #filesToImport

	update #filesToImport
		set filePath = directory + '\' + fileName
		where dirGUID = @cGUID


--if @cDirectory = 'C:\Temp\websites\BritishFasteners\BritishFasteners\www.example.com\index.php\products'
--	select * from #filesToImport where dirGUID = @cGUID order by  ukey

	delete
		from #filesToImport
		where dirGUID = @cGUID
			and (
				isnull(fileName, '') in ('', '.', '..')
				or isnull(directory, '') = ''
				)

	print '  Deleted ' + convert(varchar(20), @@rowcount) + ' dud rows'

	set @nUkey = 0
	set @nDepth = @nDepth + 1

	-- recurse into subdirectories
	while exists (select top 1 ukey from #filesToImport where ukey > @nUkey and dirGUID = @cGUID and dirString like '%<DIR>%' and isnull(filePath, '') <> '')
	begin

		select top 1
			@nUkey = ukey,
			@cThisDirectory = filePath
			from #filesToImport
			where ukey > @nUkey
				and dirGUID = @cGUID
				and dirString like '%<DIR>%'
				and isnull(filePath, '') <> ''
			order by ukey

		print 'Processing (' + convert(varchar(20), @nDepth) + '): ' + @cThisDirectory

		exec pr_recurseDirectories @cThisDirectory, @nDepth
	end

	set @nDepth = @nDepth - 1

	if @nDepth = 0
		select ukey, dirString, fileName, directory, filePath, fileDate, fileSize from #filesToImport
end
GO
