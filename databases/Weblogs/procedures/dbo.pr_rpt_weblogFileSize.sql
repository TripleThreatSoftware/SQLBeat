/****** Object:  StoredProcedure [dbo].[pr_rpt_weblogFileSize]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_weblogFileSize 'osaweb'
CREATE procedure [dbo].[pr_rpt_weblogFileSize] (@cSiteName varchar(100))
as
begin
	if isnull(@cSiteName, '') = ''
		return

	set nocount on

	declare @cWeblogPath varchar(500)
	declare @cServerName varchar(200)
	declare @nUkeySource int
	declare @cSQLString nvarchar(4000)
	declare @cDirectory varchar(500)

	set @nUkeySource = 0

	create table #filesToImport (ukey int identity, ukey_source int, dirString varchar(500), fileName varchar(500), directory varchar(500),
		filePath varchar(500), fileDate dateTime, fileSize bigint)
	create clustered index ix_tmp_filesToImport_ukey on #filesToImport (ukey) with fillfactor = 80

	while exists (select ukey from dm_sources where isEnabled = 1 and ukey > @nUkeySource)
	begin
		select top 1 @nUkeySource = ukey, @cWeblogPath = sourcePath from dm_sources where isEnabled = 1 and ukey > @nUkeySource order by ukey

		--**********************************************************

		if right(@cWeblogPath, 1) <> '\'
			set @cWeblogPath = @cWeblogPath + '\'

		--**********************************************************

		set @cServerName = convert(varchar(200), serverProperty('servername'))

		print 'Scanning : ' + @cWeblogPath

		set @cSQLString = 'dir "' + @cWeblogPath + 'ex*.log" /s'

		insert into #filesToImport (dirString)
		exec master..xp_cmdshell @cSQLString

		update #filesToImport
			set ukey_source = @nUkeySource
			where ukey_source is null
	end

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

	select
		identity(int) as ukey,
		isnull(b.friendlyName, serverName + '.' + serviceName) as siteName,
		convert(dateTime, convert(varchar(10), a.fileDate, 120)) as fileDate,
		sum(a.fileSize) as fileSize,
		count(distinct serverName + filePath) as numFiles
		into #fileHistory
		from (
			select
				right(left(filePath, 12), 10) as serverName,
				reverse(left(reverse(directory), charindex('\', reverse(directory)) - 1)) as serviceName,
				fileDate, fileSize, filePath
				from #filesToImport
			) a
		left outer join (select distinct webServer, webServerService, friendlyName from dm_sites) b on a.serverName = b.webServer
			and a.serviceName = b.webServerService
		group by isnull(b.friendlyName, serverName + '.' + serviceName),
			convert(dateTime, convert(varchar(10), a.fileDate, 120))

	select a.ukey,
		avg(b.fileSize) as fileSize
		into #averages
		from #fileHistory a
		join #fileHistory b on a.siteName = b.siteName
			and b.fileDate >= dateAdd(month, -4, a.fileDate)
			and datePart(weekDay, a.fileDate) = datePart(weekDay, b.fileDate)
			and a.ukey <> b.ukey
			and b.fileSize <> 0
		group by a.ukey

	select a.siteName,
		convert(varchar(10), a.fileDate, 120) as fileDate,
		a.numFiles,
		a.fileSize as fileSize,
		b.fileSize as fileSize_avg,
		convert(decimal(10,2), case
			when b.fileSize <> 0
				then (convert(decimal(20,4), a.fileSize) / convert(decimal(20,4), b.fileSize)) * 100
			else 100
			end) as relativeSize
		from #fileHistory a
		join #averages b on a.ukey = b.ukey
		where
			a.fileDate >= dateAdd(month, -2, getDate())
			and a.siteName = @cSiteName
		order by a.siteName, a.fileDate desc

	drop table #averages
	drop table #fileHistory
	drop table #filesToImport
end
GO
