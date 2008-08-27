--select * from dm_sources

declare @nUkeySource int
set @nUkeySource = 9

	set nocount off

	declare @cWeblogPath varchar(500)
	declare @bReadHeader bit
	declare @bisIIS bit
	declare @bisApache bit
	declare @cTimeStamp varchar(100)
	declare @nMonthsBackToLook int

	select @cWeblogPath = sourcePath,
		@bReadHeader = readHeader,
		@bisIIS = isIIS,
		@bisApache = isApache,
		@nMonthsBackToLook = monthsBackToLook
		from dm_sources
		where ukey = @nUkeySource

	--**********************************************************

	if right(@cWeblogPath, 1) <> '\'
		set @cWeblogPath = @cWeblogPath + '\'

	--**********************************************************

	declare @cSQLString nvarchar(4000)
	declare @cDirectory varchar(500)
	declare @cThisFile varchar(1000)
	declare @cModifiedFile varchar(1000)
	declare @nUkeySourceFile int
	declare @nUkeySite int
	declare @dFileDate dateTime
	declare @nFileSize bigint
	declare @cFieldList varchar(8000)
	declare @nCounter int
	declare @cFieldName varchar(200)
	declare @cTableField varchar(200)
	declare @cServerName varchar(200)
	declare @cThisSubject varchar(200)
	declare @cThisMessage varchar(8000)
	declare @dMinYMD dateTime
	declare @dMaxYMD dateTime
	declare @bDeleteFile bit
	declare @nRowsLoaded bigint

	set @cServerName = convert(varchar(200), serverProperty('servername'))

	create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500),
		filePath varchar(500), fileDate dateTime, fileSize bigint)
	create table #results (wideString varchar(8000))

	create clustered index ix_tmp_filesToImport_ukey on #filesToImport (ukey) with fillfactor = 80

	truncate table fact_weblogs_stage

	if @bisIIS = 1
		set @cSQLString = 'dir "' + @cWeblogPath + 'ex*.log" /s'

	if @bisApache = 1
		set @cSQLString = 'dir "' + @cWeblogPath + 'access_log*" /s'

	print @cSQLString

	insert into fact_weblogs_stage_hist (stepName) values ('Taking directory of ' + @cWeblogPath)

	insert into #filesToImport (dirString)
	exec master..xp_cmdshell @cSQLString

	if @@error <> 0 or (select count(*) from #filesToImport where dirString like '%access%denied%' or dirString like '%logon failure%') > 0
	begin
		set @cThisSubject = 'Unable to read from ' + @cWeblogPath + '.'
		set @cThisMessage = 'Received Access is denied reading ' + @cWeblogPath + '.'

		select @cThisMessage = @cThisMessage + char(13) + isnull(dirString, '')
			from #filesToImport

		print @cThisMessage

		insert into fact_weblogs_stage_hist (stepName) values (left(@cThisMessage, 5000))

		insert into notification..notificationLog_stage (servername, severity, subject, message) values (@cWeblogPath, 2, @cThisSubject, @cThisMessage)
	end

	insert into fact_weblogs_stage_hist (stepName) values ('Updating information on found files')

	set @cDirectory = ''

	update #filesToImport
		set @cDirectory = directory = case
			when dirString like '%directory of%' then substring(dirString, charindex('\', dirString), 500)
			else @cDirectory end,
			fileDate = case when isDate(left(dirString, 22)) = 1 then convert(dateTime, left(dirString, 22)) else null end,
			fileSize = case when dirString like '%.log%' or dirString like '%access_log%'
				then dbo.fn_returnDigits(left(ltrim(substring(dirString, 22, 99)), charindex(' ', ltrim(substring(dirString, 22, 99)))), 0) else 0 end,
			fileName = case when dirString like '%.log%' or dirString like '%access_log%'
				then rtrim(ltrim(right(rtrim(ltrim(dirString)), charindex(' ', reverse(rtrim(ltrim(dirString)))))))
				else null end
		from #filesToImport

	update #filesToImport
		set filePath = directory + '\' + fileName

	delete from #filesToImport where isnull(fileName, '') = '' or isnull(directory, '') = ''

	-- if they're still being written and the file is on a network share (read: locked), don't bother
	delete from #filesToImport where dateDiff(minute, fileDate, getDate()) < 10 and charindex('\\', filePath) > 0 and @bIsApache = 0

	-- get rid of anything we've already added
	delete #filesToImport
		from #filesToImport a
		join dm_sourceFiles b on a.filePath = b.sourceFile
			and a.fileSize = b.fileSize
--			and a.fileDate = b.fileDate

	-- don't bother importing any file we've already failed on twice
	delete #filesToImport
		from #filesToImport a
		join dm_sourceFiles b on a.filePath = b.sourceFile
			and b.errors >= 10

	-- get rid of anything more than six months old
	delete from #filesToImport
		where fileDate < dateAdd(month, -@nMonthsBackToLook, getDate())

	-- temporary rule!!
	delete from #filesToImport where filePath like '%ex071124.log' or filePath like '%ex071123.log'
	delete from #filesToImport where filePath like '%.log%' and right(filePath, 4) <> '.log'

	-- we really don't want to pull in more than 50 files at a time
	delete from #filesToImport
		where fileDate < (
			select top 1 fileDate
				from (
					select top 50 fileDate
						from #filesToImport
						where fileDate > dateAdd(month, -6, getDate())
						order by fileDate desc
					) a
				order by fileDate
			)

select * from #filesToImport

go

drop table #filesToImport
drop table #results
