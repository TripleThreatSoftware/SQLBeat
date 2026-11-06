/****** Object:  StoredProcedure [dbo].[pr_archiveWeblogFiles]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec pr_archiveWeblogFiles 'appweb37'
CREATE proc [dbo].[pr_archiveWeblogFiles] (@cServerName varchar(200))
as
begin
	-- job on mon42
	--declare @cServerName varchar(200) = 'appweb37'
	declare @cSQLCommand nvarchar(4000)
	declare @cFilePath varchar(500)
	declare @cNewFileName7z varchar(500)
	declare @cLogFolderPath varchar(500)
	declare @cStorageFolderPath varchar(500)
	declare @cFolderPathCreate varchar(500)
	declare @nUkey int
	declare @nUkeyServer int

	create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)
	create clustered index ix_tmp_filesToImport on #filesToImport (ukey) with fillfactor = 60

	set @cLogFolderPath = '\\' + @cServerName + '\logs\logfiles'

	exec sandbox.dbo.pr_recurseDirectories @cLogFolderPath

	--select * from #filesToImport

	-- 12 hours or older
	delete a
		from #filesToImport a
		where fileDate > dateadd(hh, -12, getdate())

	delete a
		from #filesToImport a
		where filesize = 0

	alter table #filesToImport add [year] varchar(4), [month] varchar(3), [day] varchar(3), storageFolderPath varchar(500), newFileName varchar(500), newFileName7z varchar(500)

	update #filesToImport
		set newFileName = replace(replace(filePath, '\\' + @cServerName + '\logs\logfiles\', ''), '\', '_')

	update #filesToImport
		set newFileName7z = replace(newFileName, '.log', '.7z')

	update #filesToImport
		set [year] = convert(varchar(4), datepart(yy, fileDate)),
			[month] = convert(varchar(2), datepart(month, fileDate)),
			[day] = convert(varchar(2), datepart(dd, filedate))

	update #filesToImport
		set [month] = '0' + [month]
		where len([month]) = 1

	update #filesToImport
		set [day] = '0' + [day]
		where len([day]) = 1

	update #filesToImport
		set storageFolderPath = '\\storage01\d$\weblogs\' + [year] + '\' + [month] + '\' + @cServerName

	--select * from #filesToImport

	create table #output (widestring varchar(8000))

	insert into #output (widestring)
	exec xp_cmdshell 'dir /s /b /o:n /a:d \\storage01\d$\weblogs\'

	select distinct
		identity(int) as ukey,
		storageFolderPath
		into #directories
		from #filesToImport

	delete a
		from #directories a
		join #output b on a.storageFolderPath = b.widestring

	--select * from #directories

	set @nUkey = 0

	while exists (select top 1 ukey from #directories where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@cFolderPathCreate = storageFolderPath
			from #directories
			where ukey > @nUkey
			order by ukey

		set @cSQLCommand = 'md ' + @cFolderPathCreate

		--print @cSQLCommand

		exec xp_cmdshell @cSQLCommand

	end

	drop table #output
	drop table #directories

	set @nUkey = 0
	set @cSQLCommand = ''

	while exists (select top 1 ukey from #filesToImport where ukey > @nUkey)
	begin

		select top 1
			@nUkey = ukey,
			@cStorageFolderPath = storageFolderPath,
			@cNewFileName7z = newFileName7z,
			@cFilePath = filePath
			from #filesToImport
			where ukey > @nUkey
			order by ukey

		set @cSQLCommand = '"c:\Program Files\7-Zip\7z.exe" a ' + @cStorageFolderPath + '\' + @cNewFileName7z + ' ' + @cFilePath + ' -sdel'

		--print @cSQLCommand

		exec xp_cmdshell @cSQLCommand

	end
	drop table #filesToImport


end
GO
