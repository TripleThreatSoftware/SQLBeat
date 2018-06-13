USE [Audit]
GO
/****** Object:  StoredProcedure [dbo].[pr_monitorFiles]    Script Date: 6/13/2018 8:06:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- use audit
-- exec pr_monitorFiles '\\web01\inetpub\sites'
-- select * from auditData_files where filePath = '\\web01\inetpub\sites\AppSecure\manage\home.aspx'
ALTER procedure [dbo].[pr_monitorFiles] (@cPath varchar(500))
as
begin

	-- create table auditData_files (ukey int identity, directory varchar(2000), filePath varchar(2000), fileDate dateTime, fileSize int, fileName varchar(500), scanDate dateTime)
	-- truncate table auditData_files

	create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)
	create clustered index ix_tmp_filesToImport_ukey on #filesToImport (ukey) with fillfactor = 60
	declare @dScanDate dateTime
	set @dScanDate = getDate()

	exec pr_recurseDirectories @cPath

	alter table #filesToImport add lastSize int, lastDate dateTime
	alter table #filesToImport add lastScan dateTime

	update #filesToImport set lastSize = null, lastDate = null

	update #filesToImport
		set lastScan = b.lastScan
		from #filesToImport a
		join (
			select a.ukey, max(b.scanDate) as lastScan
				from #filesToImport a
				left outer join auditData_files b on isnull(a.directory, '') = isnull(b.directory, '')
					and isnull(a.filePath, '') = isnull(b.filePath, '')
					and isnull(a.fileName, '') = isnull(b.fileName, '')
					and b.scanDate < @dScanDate
				group by a.ukey
			) b on a.ukey = b.ukey

	update #filesToImport
		set lastSize = c.fileSize, lastDate = c.fileDate
		from #filesToImport a
		join auditData_files c on isnull(a.directory, '') = isnull(c.directory, '')
			and isnull(a.filePath, '') = isnull(c.filePath, '')
			and isnull(a.fileName, '') = isnull(c.fileName, '')
			and c.scanDate = a.lastScan
		where a.lastScan is not null

	-- add new/changed files
	insert into auditData_files (directory, filePath, fileName, fileDate, fileSize, scanDate)
	select distinct a.directory, a.filePath, a.fileName, a.fileDate, a.fileSize, @dScanDate
		from #filesToImport a
		where a.filePath is not null
			and (
				isnull(lastSize, 0) <> isnull(fileSize, 0)
				or isnull(lastDate, '') <> isnull(fileDate, '')
				)

	print convert(varchar(20), @@rowcount) + ' new/changed objects'

	delete from #filesToImport where filePath like '%\avenue\%'
	delete from #filesToImport where filePath like '%\error%xml'
	delete from #filesToImport where filePath like '%well-known'
	delete from #filesToImport where filePath like '%acme-challenge'
	delete from #filesToImport where filePath like '%wkhtmltopdf%'
	delete from #filesToImport where isnull(lastSize, 0) = 0 and isnull(fileSize, 0) = 0 -- directories

	declare @cTo varchar(100)
	declare @cFrom varchar(100)
	declare @cSubject varchar(500)
	declare @cBody varchar(4000)
	declare @nUkey int
	declare @nRowCount int

	--declare @dScanDate dateTime
	--set @dScanDate = getDate()

	set @cTo = 'alerts@triplethreatsoftware.com'
	--set @cTo = 'alerts@example.com'
	set @cFrom = 'alerts@example.com'

	select *
		into #toSend
		from #filesToImport
		where isnull(lastSize, 0) <> isnull(fileSize, 0)
			or isnull(lastDate, '') <> isnull(fileDate, '')
		order by ukey

--select * from #tosend
--return

	set @nRowCount = @@rowcount

	if @nRowCount = 0
		print 'No files changed'

	if @nRowCount > 25
	begin
		set @cSubject = convert(Varchar(20), @nRowCount) + ' files changed in ' + isnull(@cPath, 'N/A')
		set @cBody = ''

		select @cBody = left(@cBody + filePath + '<br>', 4000)
			from (select top 250 filePath from #toSend order by filePath) a

		exec notification.dbo.pr_sendMessage @cFrom, @cTo, @cSubject, @cBody, 1
	end
	else
	begin

		set @nUkey = 0
		while exists (select top 1 ukey from #toSend where ukey > @nUkey)
		begin
			select top 1
				@nUkey = ukey,
				@cSubject = 'Changed File: ' + isnull(filePath, 'N/A') + ' @ ' + isnull(convert(varchar(20), fileDate, 120), 'N/A'),
				@cBody = 'File "' + isnull(filePath, '') + '" changed in the ' + convert(varchar(20), @dScanDate, 120) + ' scan pass.' + '<br>' +
					'Date (old): ' + isnull(convert(varchar(20), lastDate, 120), 'N/A') + '<br>' +
					'Date (new): ' + isnull(convert(varchar(20), fileDate, 120), 'N/A') + '<br>' +

					'Size (old): ' + isnull(convert(varchar(20), lastSize), 'N/A') + '<br>' +
					'Size (new): ' + isnull(convert(varchar(20), fileSize), 'N/A')
				from #toSend
				where ukey > @nUkey
				order by ukey

			print @cSubject
			print @cBody

			exec notification.dbo.pr_sendMessage @cFrom, @cTo, @cSubject, @cBody, 1
		end

	end

	drop table #filesToImport
	drop table #toSend

	--select * from auditData_files where scanDate = @dScanDate
	--select top 100 * from auditData_Files order by fileDate desc
end
