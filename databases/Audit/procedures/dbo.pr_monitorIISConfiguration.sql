-- ================================================================================================
-- Audit.dbo.pr_monitorIISConfiguration
--
-- Builds a manifest of a server's configuration files and keeps their history and changes in
-- auditData_config. By default this covers every web.config under inetpub, the .NET framework
-- web.config, machine.config and aspnet.config, and the IIS schema and administration config files
-- under System32\inetsrv\config. Job: "IIS Monitor - [SERVERNAME]".
-- ================================================================================================
/****** Object:  StoredProcedure [dbo].[pr_monitorIISConfiguration]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select top 100 * from auditData_config where fileString like '%the network path%' order by ymd desc
-- exec master..xp_cmdshell 'dir \\appweb34\inetpub'
-- exec master..xp_cmdshell 'type \\appweb34\inetpub\sites\App_Nodes\App_Brand_Region\Web.config'
-- exec pr_monitorIISConfiguration 'appweb37'
CREATE procedure [dbo].[pr_monitorIISConfiguration] (@cServerName varchar(100))
as
begin

-- declare @cServerName varchar(100) = 'web02'

	declare @cFilePath varchar(500)
	declare @cSQLString nvarchar(500)
	declare @nChangedLines int
	declare @nNewLines int
	declare @nDroppedLines int
	declare @cTo varchar(100)
	declare @cFrom varchar(100)
	declare @cSubject varchar(500)
	declare @cBody varchar(4000)
	declare @nChangedFiles int

	set @cTo = 'cole@sqlbeat.com'
	set @cFrom = 'monitor@sqlbeat.com'

	set nocount on

	create table #configFile (serverName varchar(100), filePath varchar(1000), wideString varchar(8000), ukey int identity, lineNumber int)
	create clustered index ix_configfile_ukey on #configFile (ukey) with fillfactor = 80

	set @cFilepath = ''

	-- select top 100 * From auditData_files where filepath like '%web02%' and scanDate >= dateadd(week, -1, getDate()) and fileName = 'web.config'

	select distinct filePath into #files from auditData_files with (nolock) where directory like '\\' + @cServerName + '\inetpub%' and fileName = 'web.config' and scanDate >= dateadd(week, -1, getDate())
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\Windows\microsoft.net\framework\v4.0.30319\config\web.config')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\Windows\microsoft.net\framework\v4.0.30319\config\machine.config')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\Windows\microsoft.net\framework\v4.0.30319\aspnet.config')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\Windows\microsoft.net\framework\v2.0.50727\config\web.config')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\Windows\microsoft.net\framework\v2.0.50727\config\machine.config')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\windows\System32\inetsrv\config\schema\iis_schema.xml')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\windows\System32\inetsrv\config\schema\deploymentauthorizationschema.xml')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\windows\System32\inetsrv\config\schema\aspnet_schema.xml')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\windows\System32\inetsrv\config\administration.config')
	insert into #files (filePath) values ('\\' + @cServerName + '\c$\windows\System32\inetsrv\config\applicationHost.config')

	delete from #files where filePath like '%acme-challenge%'

	-- select * from #files

	while exists (select top 1 filePath from #files where filePath > @cFilePath)
	begin
		select top 1 @cFilePath = filepath
			from #files
			where filePath > @cFilePath
			order by filePath

		print @cFilePath

		set @cSQLString = 'type ' + @cFilePath

		insert into #configFile (wideString)
		exec master..xp_cmdshell @cSQLString
		update #configFile set servername = '' + @cServerName + '', filePath = @cFilePath where servername is null
	end

	set nocount off

-- select * from #configFile where filePath = '\\web02\inetpub\sites\App_Nodes\App_Brand_Region\Web.config'

	insert into notification.dbo.notificationLog_stage (servername, ymd, subject, message, severity, isConfiguration)
	select distinct servername, convert(varchar(10), getDate(), 120), '"' + wideString + '"' + ' reading "' + filePath + '"',  '"' + wideString + '"' + ' reading "' + filePath + '"', 2, 1
		-- select *
		from #configFile
		where wideString like '%the network path was not found%'
			or wideString like '%cannot find the path%'

	delete
		from #configFile
		where wideString like '%the network path was not found%'
			or wideString like '%cannot find the path%'

	insert into notification.dbo.notificationLog_stage (servername, ymd, subject, message, severity, isConfiguration)
	select distinct servername, getDate(), '"' + wideString + '"' + ' reading "' + filePath + '"',  '"' + wideString + '"' + ' reading "' + filePath + '"', 2, 1
		from #configFile
		where widestring = 'access is denied.'

	delete from #configFile where widestring = 'access is denied.'

	-- alter table #configFile add lineNumber int

	update #configFile
		set lineNumber = a.ukey - b.minUkey + 1
		from #configFile a
		join (
			select filePath, min(ukey) as minUkey
				from #configFile
				group by filePath
			) b on a.filePath = b.filePath

	--set nocount off
	-- select * from #changedFiles
	select a.filePath, count(*) as changedLines
		into #changedFiles
		from #configFile a
		left outer join auditdata_config b on a.filePath = b.filePath
			and isnull(a.wideString, '') = isnull(b.fileString, '')
			and a.lineNumber = b.lineNumber
			and b.isCurrent = 1
		where b.ukey is null
			and not a.wideString like '%access is denied%'
			and not a.wideString like '%the network path was not found%'
			and not a.wideString like '%cannot find the path%'

			and not b.fileString like '%access is denied%'
			and not b.fileString like '%the network path was not found%'
			and not b.fileString like '%cannot find the path%'

		group by a.filePath

	-- select * from #changedFilesNewLines
	select a.filePath, a.lineNumber
		into #changedFilesNewLines
		from #configFile a
		left outer join auditdata_config b on a.filePath = b.filePath
			and isnull(a.wideString, '') = isnull(b.fileString, '')
			and b.isCurrent = 1
		where b.ukey is null
			and not a.wideString like '%access is denied%'
			and not a.wideString like '%the network path was not found%'
			and not a.wideString like '%cannot find the path%'

	-- select top 100 * from auditdata_config
	-- select * from #changedFilesdroppedLines
	-- drop table #changedFilesdroppedLines
	select a.filePath, a.lineNumber
		into #changedFilesdroppedLines
		from auditdata_config a with (nolock)
		left outer join #configFile b on a.filePath = b.filePath
			and isnull(b.wideString, '') = isnull(a.fileString, '')
		where b.ukey is null
			and a.isCurrent = 1
			and a.servername = @cServerName
			and isnull(a.fileString, '') <> ''
			and not a.fileString like '%access is denied%'
			and not a.fileString like '%the network path was not found%'
			and not a.fileString like '%cannot find the path%'

	insert into #changedFiles (filePath, changedLines)
	select a.filePath, numLines
		from (select filePath, count(*) as numLines from #changedFilesdroppedLines group by filePath) a
		left outer join #changedFiles b on a.filePath = b.filePath
		where b.filePath is null


	set @nChangedFiles = (select count(*) from #changedFiles)

	if isnull(@nChangedFiles, 0) > 20
	begin
--declare @cBody varchar(8000)
--declare @cServerName varchar(100) = 'web02'
--declare @nChangedFiles int = (select count(*) from #changedFiles)

		set @cBody = ''

		select @cBody = @cBody + filePath + ' (' + convert(varchar(20), changedLines) + ')<br>'
			from #changedFiles

		insert into notification.dbo.notificationLog_stage (servername, ymd, subject, message, severity, isConfiguration)
		select @cServerName, getDate(), convert(varchar(20), @nChangedFiles) + ' files changed', @cBody, 2, 1

	end
	else
	begin

		set @cFilePath = ''

		while exists (select top 1 filePath from #changedFiles where filePath > @cFilePath)
		begin
			select top 1
				@cFilePath = filePath,
				@nChangedLines = changedLines
				from #changedFiles
				where filePath > @cFilePath
				order by filePath

			select top 1
				@nNewLines = count(*)
				from #changedFilesNewLines
				where filePath = @cFilePath

			select top 1
				@nDroppedLines = count(*)
				from #changedFilesDroppedLines
				where filePath = @cFilePath

			set @cBody = ''
			set @nChangedLines = isnull(@nChangedLines, 0)
			set @nNewLines = isnull(@nNewLines, 0)
			set @nDroppedLines = isnull(@nDroppedLines, 0)

			if @nChangedLines <= 20
			begin

				select @cBody = @cBody +
	'LINE ' + convert(varchar(20), lineNumber) + '
		NEW: ' + isnull(wideString, '') + '
		OLD: ' + isnull(fileString, '') + char(13) + char(13)
					from (
						select top 20
							a.lineNumber,
							replace(a.wideString, char(9), '') as wideString,
							replace(b.fileString, char(9), '') as fileString
							from #configFile a
							left outer join auditdata_config b with (nolock) on a.filePath = b.filePath
								and a.lineNumber = b.lineNumber
								and b.isCurrent = 1
							where not (isnull(a.wideString, '') = isnull(b.fileString, ''))
								and a.filePath = @cFilePath
							order by a.lineNumber
						) a

				select @cBody = @cBody +
	'LINE ' + convert(varchar(20), lineNumber) + '
		NEW: [LINE REMOVED]
		OLD: ' + isnull(fileString, '') + char(13) + char(13)

					from (
						select top 20 a.lineNumber, replace(b.wideString, char(9), '') as wideString, replace(a.fileString, char(9), '') as fileString
							from auditdata_config a with (nolock)
							left outer join #configFile b on a.filePath = b.filePath
								and a.lineNumber = b.lineNumber
							where a.isCurrent = 1
								and b.filepath is null
								and a.filePath = @cFilePath
							order by a.lineNumber
						) a

			end
			else
			begin
				if @nNewLines + @nDroppedLines < @nChangedLines
					set @nChangedLines = @nNewLines + @nDroppedLines

				if @nNewLines <= 20 and @nNewLines > 0
				begin
				select @cBody = @cBody +
	'LINE ' + convert(varchar(20), lineNumber) + ' ADDED
		' + isnull(wideString, '') + char(13) + char(13)
					from (
						select top 20
							a.lineNumber,
							replace(a.wideString, char(9), '') as wideString
							from #configFile a
							join #changedFilesNewLines b on a.lineNumber = b.linenumber
								and b.filePath = a.filePath
							where a.filePath = @cFilePath
							order by a.lineNumber
						) a
				end

				if @nDroppedLines <= 20 and @nDroppedLines > 0
				begin
				select @cBody = @cBody +
	'LINE ' + convert(varchar(20), lineNumber) + ' REMOVED
		' + isnull(fileString, '') + char(13) + char(13)

					from (
						select top 20 a.lineNumber, replace(a.fileString, char(9), '') as fileString
							from auditdata_config a with (nolock)
							join #changedFilesDroppedLines b on a.lineNumber = b.linenumber
								and b.filePath = a.filePath
							where a.isCurrent = 1
								and a.filePath = @cFilePath
							order by a.lineNumber
						) a
				end

				if isnull(@cBody, '') = ''
					set @cBody = convert(varchar(20), @nChangedLines) + ' lines changed in file ' + @cFilepath
			end

			set @cSubject = '[' + convert(varchar(20), @nChangedLines) + ' lines changed] ' + @cFilepath

			set @cBody = @cBody + char(13) + char(13) +
				'Scan date: ' + convert(varchar(20), getDate(), 120)

			--print @cSubject
			--print @cBody

			exec notification.dbo.pr_sendMessage @cFrom, @cTo, @cSubject, @cBody, 0
		end
	end

	update a
		set isCurrent = 0
		-- select *
		from auditData_config as a with (nolock)
		join #changedFiles b on a.filePath = b.filePath
		where a.isCurrent = 1

	-- select top 100 * from auditData_config
	-- declare @cServerName varchar(100) = 'web0w'
	insert into auditData_config (servername, filepath, filestring, iscurrent, linenumber)
	select @cServerName, a.filePath, a.widestring, 1, a.lineNumber
		from #configFile a
		join #changedFiles b on a.filePath = b.filePath
		order by a.filePath, a.ukey

	drop table #changedFiles
	drop table #changedFilesNewLines
	drop table #changedFilesDroppedLines
	drop table #configFile
	drop table #files
end

--select * from #configFile where servername = '' + @cServerName + '' order by ukey

--exec master..xp_cmdshell 'dir \\' + @cServerName + '\c$\Windows\microsoft.net\framework'
--exec master..xp_cmdshell 'dir \\' + @cServerName + '\c$\Windows\microsoft.net\framework\v3.5\msbuild'
--exec master..xp_cmdshell 'dir \\' + @cServerName + '\c$\Windows\microsoft.net\framework\v4.0.30319\*.config'
--exec master..xp_cmdshell 'dir \\' + @cServerName + '\c$\Windows\microsoft.net\framework\v4.0.30319\config'

--exec master..xp_cmdshell 'dir /s \\' + @cServerName + '\inetpub\*.config'
GO
