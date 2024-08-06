/****** Object:  StoredProcedure [dbo].[pr_scanDataImport]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[pr_scanDataImport] @cPathToScan varchar(8000) = null, @bLogDirCommand bit = 0
as

-- dbo.pr_scanDataImport is called by sqlbeat42 SQL Agent Job "SQL Scripts Audit" Fridays at 9 p.m.

-- truncate table Audit.dbo.auditData_SQLFileText
-- select count(0) from Audit.dbo.auditData_SQLFileText (nolock)
-- dbo.pr_scanDataImport '\\etl01\e\data_import', 1


begin
	set nocount on

	declare @cCommand varchar(8000)
	declare @cDirectory varchar(500)
	declare @cFileName varchar(500)
	declare @fullFileName varchar(8000)
	declare @cFileContents varchar(8000)

	if object_id('Audit.dbo.fileText') is null
	begin
		create table dbo.fileText (ukey int identity, filePath varchar(500), fileName varchar(200), lineID int, fileText varchar(8000), isChanged bit default 0, textChecksum bigint)

		create clustered index cix_Checksum_Text_Path_File on dbo.fileText (textChecksum, fileText, filePath, fileName)
		create index ix_isChanged on dbo.fileText (isChanged)
	end

	truncate table dbo.fileText

	if object_id('tempdb.dbo.#fileContents') is not null
		drop table #fileContents

	create table #fileContents (lineNumber int identity, lineContents varchar(8000))

	if object_id('tempdb.dbo.#filesToImport') is not null
		drop table #filesToImport

	create table #filesToImport (ukey int identity, fileName varchar(500), directory varchar(500), fullFileName varchar(500))
	create clustered index ix_tmp_filesToImport on #filesToImport (ukey) with fillfactor = 60

	-- Start of integrated directory scan process (replaces line set @cCommand = 'dbo.pr_recurseDirectories ''' + @cPathToScan + '''')
	if object_id('tempdb.dbo.#fileList') is not null
		drop table #fileList

	create table #fileList(fileNumber int identity, fullFileName varchar(2000))

	set @cCommand = 'dir ' + @cPathToScan + '\*.sql /b /s /a:-D'

	if isnull(@bLogDirCommand, 0) = 1
	begin
		set @cCommand = 'dir ' + @cPathToScan + '\*.sql /b /s /a:-D > \\etl01\e\data_import\recursiveDirResults.log'

		exec xp_cmdshell @cCommand

		set @cCommand = 'type "\\etl01\e\data_import\recursiveDirResults.log"'
	end

	insert #fileList
	exec master.dbo.xp_cmdshell @cCommand

	insert #filesToImport(fullFileName, directory, fileName)
	select replace(fullFileName, '\' + reverse(substring(reverse(fullFileName), 1, charindex('\', reverse(fullFileName)) - 1)), '') + '\' + reverse(substring(reverse(fullFileName), 1, charindex('\', reverse(fullFileName)) - 1)) fullFileName,
		replace(fullFileName, '\' + reverse(substring(reverse(fullFileName), 1, charindex('\', reverse(fullFileName)) - 1)), '') pathName,
		reverse(substring(reverse(fullFileName), 1, charindex('\', reverse(fullFileName)) - 1)) fileName
		from #fileList
		where fullFileName is not null
	-- End of integrated directory scan process

	select * from #filesToImport order by fullFileName

	set @fullFileName = ''

	while exists (select top 1 fullFileName from #filesToImport where fullFileName > @fullFileName)
	begin
		select top 1
			@fullFileName = fullFileName,
			@cDirectory = directory,
			@cFileName = filename
			from #filesToImport
			where fullFileName > @fullFileName
			order by fullFileName

		print 'Ingesting text of SQL script ' + @fullFileName

		set @cCommand = 'type "' + @fullFileName + '"'

		insert #fileContents
		exec master.dbo.xp_cmdshell @cCommand

		insert fileText(filePath, fileName, lineID, fileText)
		select @cDirectory, @cFileName, lineNumber, isnull(lineContents, '')
			from #fileContents

		truncate table #fileContents
	end

	update fileText
		set textChecksum = notification.dbo.fn_checksum(isnull(fileText, ''))

	-- find things that don't currently exist in the table
	update fileText
		set isChanged = 1
		from fileText a (nolock)
		left outer join Audit.dbo.auditData_SQLFileText b on a.textChecksum = b.textChecksum
			and isnull(a.filePath, '') = isnull(b.filePath, '')
			and isnull(a.fileName, '') = isnull(b.fileName, '')
			and isnull(a.lineID, '') = isnull(b.lineID, '')
		where b.ukey is null

	-- anything in the table that is in the current snapshot, update
	update Audit.dbo.auditData_SQLFileText
		set ymd_lastSeen = getDate(),
			isCurrent = 1,
			lineID = b.lineID
		from Audit.dbo.auditData_SQLFileText a (nolock)
		join fileText b on isnull(a.filePath, '') = isnull(b.filePath, '')
			and isnull(a.fileName, '') = isnull(b.fileName, '')
			and isnull(a.lineID, '') = isnull(b.lineID, '')
			and a.textChecksum = b.textChecksum

	-- anything in the table but not in the snapshot, mark as gone!
	update Audit.dbo.auditData_SQLFileText
		set isCurrent = 0
		from Audit.dbo.auditData_SQLFileText a (nolock)
		left outer join fileText b on isnull(a.filePath, '') = isnull(b.filePath, '')
			and isnull(a.fileName, '') = isnull(b.fileName, '')
			and isnull(a.lineID, '') = isnull(b.lineID, '')
			and a.textChecksum = b.textChecksum
		where b.ukey is null

	-- add new things to the table
	insert into Audit.dbo.auditData_SQLFileText(filePath, fileName, lineID, fileText, textChecksum, isCurrent)
	select filePath, fileName, lineID, fileText, textChecksum, 1
		from fileText
		where isChanged = 1
		order by ukey
end
GO
