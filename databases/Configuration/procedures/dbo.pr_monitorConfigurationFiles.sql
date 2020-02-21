USE [Configuration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- select top 100 * from configFileLog order by ymd desc
ALTER procedure [dbo].[pr_monitorConfigurationFiles]
as
begin

	delete from configFileLog where ymd < dateadd(day, -180, getDate())

	declare @cDirectory varchar(2000)
	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(100)
	declare @nUkey int
	declare @cTagPath varchar(2000)
	declare @cFileName varchar(2000)
	declare @cTagString varchar(8000)
	declare @cTagFriendlyName varchar(500)
	declare @cTagName varchar(100)
	declare @nCharacter int
	declare @cCharacter varchar(1)
	declare @bInTag bit
	declare @bInString bit
	declare @bInTagName bit
	declare @bInComment bit

	create table #directories (directoryName varchar(500), fullpath varchar(2000), servername varchar(100))
	create table #configFiles (ukey int identity, fileName varchar(2000), fileString varchar(8000), tagPath varchar(8000), ukey_parent int, tagName varchar(500), tagKey varchar(500), servername varchar(100), lineNumber int)

	create clustered index ix_configfiles_ukey on #configFiles (ukey) with fillfactor = 80

	declare @servers table (servername varchar(100))
	insert into @servers (servername) values ('web01')
	insert into @servers (servername) values ('web02')
	insert into @servers (servername) values ('web34')

	set @cServerName = ''

	while exists (select top 1 servername from @servers where servername > @cServerName)
	begin

		select top 1 @cServerName = servername from @servers where servername > @cServerName order by servername

		set @cSQLString = 'dir /b \\' + @cServerName + '\inetpub\sites'

		insert into #directories (directoryName)
		exec master..xp_cmdshell @cSQLString

		delete from #directories where directoryName is null or not directoryName like '%AppDb%'

		update #directories set fullpath = '\\' + @cServerName + '\inetpub\sites\' + directoryName, servername = @cServerName where fullpath is null

		set @cSQLString = 'dir /b \\' + @cServerName + '\inetpub\sites\App_Nodes'

		insert into #directories (directoryName)
		exec master..xp_cmdshell @cSQLString

		delete from #directories where directoryName is null

		update #directories set fullpath = '\\' + @cServerName + '\inetpub\sites\App_Nodes\' + directoryName, servername = @cServerName where fullpath is null

		--********************************************************************************************************************
		--********************************************************************************************************************

		if @cServerName in ('web34')
			set @cSQLString = 'type \\' + @cServerName + '\inet-config\applicationHost.config'
		else
			set @cSQLString = 'type \\' + @cServerName + '\c$\windows\system32\inetsrv\config\applicationHost.config'

		insert into #configFiles (fileString)
		exec master..xp_cmdshell @cSQLString

		if exists (select top 1 fileString from #configFiles where fileName is null and fileString in ('Access is denied.', 'The system cannot find the file specified.'))
		begin
			print 'Unable to access \\' + @cServerName + '\c$\windows\system32\inetsrv\config\applicationHost.config'

			delete from #configFiles where fileName is null
		end
		else
		begin
			update #configFiles
				set fileName = '\\' + @cServerName + '\c$\windows\system32\inetsrv\config\applicationHost.config', servername = @cServerName
				where fileName is null
		end


		--********************************************************************************************************************
		--********************************************************************************************************************

		if @cServerName in ('web34')
			set @cSQLString = 'type \\' + @cServerName + '\inet-config\administration.config'
		else
			set @cSQLString = 'type \\' + @cServerName + '\inet-config\administration.config'

		insert into #configFiles (fileString)
		exec master..xp_cmdshell @cSQLString

		if exists (select top 1 fileString from #configFiles where fileName is null and fileString in ('Access is denied.', 'The system cannot find the file specified.'))
		begin
			print 'Unable to access \\' + @cServerName + '\c$\windows\system32\inetsrv\config\administration.config'

			delete from #configFiles where fileName is null
		end
		else
		begin
			update #configFiles
				set fileName = '\\' + @cServerName + '\c$\windows\system32\inetsrv\config\administration.config', servername = @cServerName
				where fileName is null
		end

		--********************************************************************************************************************
		--********************************************************************************************************************

		if @cServerName in ('web34')
			set @cSQLString = 'type \\' + @cServerName + '\inet-config\redirection.config'
		else
			set @cSQLString = 'type \\' + @cServerName + '\inet-config\redirection.config'

		insert into #configFiles (fileString)
		exec master..xp_cmdshell @cSQLString

		if exists (select top 1 fileString from #configFiles where fileName is null and fileString in ('Access is denied.', 'The system cannot find the file specified.'))
		begin
			print 'Unable to access \\' + @cServerName + '\c$\windows\system32\inetsrv\config\redirection.config'

			delete from #configFiles where fileName is null
		end
		else
		begin
			update #configFiles
				set fileName = '\\' + @cServerName + '\c$\windows\system32\inetsrv\config\redirection.config', servername = @cServerName
				where fileName is null
		end
	end


	set @cDirectory = ''

	while exists (select top 1 directoryName from #directories where fullpath > @cDirectory)
	begin
		select top 1
			@cDirectory = fullpath,
			@cServerName = servername
			from #directories
			where fullpath > @cDirectory
			order by fullpath

		set @cSQLString = 'type ' + @cDirectory + '\web.config'

		print @cSQLString

		insert into #configFiles (fileString)
		exec master..xp_cmdshell @cSQLString

		if exists (select top 1 fileString from #configFiles where fileName is null and fileString in ('Access is denied.', 'The system cannot find the file specified.'))
		begin
			print 'Unable to access ' + @cDirectory + '\web.config'

			delete from #configFiles where fileName is null
		end
		else
		begin
			update #configFiles
				set fileName = @cDirectory + '\web.config', servername = @cServerName
				where fileName is null
		end
	end


	delete from #configFiles where fileString is null

	--*******************************************************************************************************************************************************
	--*******************************************************************************************************************************************************

	update #configFiles
		set tagName = replace(substring(fileString, charindex('bindinginformation="', fileString), 500), 'bindinginformation="', '')
		where charindex('bindinginformation="', fileString) > 0

	update #configFiles
		set tagName = substring(fileString, charindex('key="', fileString) + 5, 500)
		where charindex('key="', fileString) > 0

	update #configFiles
		set tagName = substring(fileString, charindex('name="', fileString) + 6, 500)
		where charindex('name="', fileString) > 0

	update #configFiles
		set tagName = substring(fileString, charindex('path="', fileString) + 6, 500)
		where charindex('path="', fileString) > 0

	update #configFiles
		set tagName = left(tagName, charindex('"', tagName) - 1)
		where charindex('"', tagName) > 0

	update #configFiles
		set tagName = null
		where fileString like '%<sectionGroup%'

	--*******************************************************************************************************************************************************
	--*******************************************************************************************************************************************************

	set @nUkey = 0
	set @cTagPath = ''
	set @cFileName = ''

	set nocount on

	while exists (select top 1 fileName from #configFiles where fileName > @cFileName) -- and fileName = '\\web01\c$\windows\system32\inetsrv\config\applicationHost.config'
	begin

		select top 1 @cFileName = fileName from #configFiles where fileName > @cFileName order by fileName -- and fileName = '\\web01\c$\windows\system32\inetsrv\config\applicationHost.config'

		set @nUkey = 0
		set @cTagPath = ''
		set @bInComment = 0
		set @bInString = 0
	--	set @bInTag = 0


		while exists (select top 1 ukey from #configFiles where fileName = @cFileName and ukey > @nUkey)
		begin
			select top 1 @nUkey = ukey, @cTagString = fileString, @cTagFriendlyName = tagName from #configFiles where fileName = @cFileName and ukey > @nUkey order by ukey

			update #configFiles set tagPath = null where ukey = @nUkey

			set @nCharacter = 1
	--		set @bInString = 0
			set @bInTag = 0
	--		set @bInComment = 0
			set @bInTagName = 0
	--		set @cTagName = ''

	--		print case when @bInComment = 1 then '[COMMENT] ' else '' end + @cTagString

			while @nCharacter <= len(@cTagString)
			begin
				set @cCharacter = substring(@cTagString, @nCharacter, 1)

				if @cCharacter = '<' and @bInString = 0 and @bInComment = 0 and @bInTag = 0
				begin

					set @bInTagName = 1
					set @bInTag = 1
					set @cTagName = ''
				end

				if (@cCharacter = '"' or @cCharacter = '''') and @bInComment = 0
					if @bInString = 1
						set @bInString = 0
					else
						set @bInString = 1

				if @bInTagName = 1 and substring(@cTagString, @nCharacter, 3) = '<!-'
				begin
					set @bInComment = 1
					set @bInTagName = 0
					set @cTagPath = @cTagPath + '.Comment'
				end
				else
				begin

					if @bInTagName = 1 and not @cCharacter in ('<', ' ', '>', '/')
						set @cTagName = @cTagName + @cCharacter

					if @bInTagName = 1 and @cCharacter in (' ', '>')
					begin
						set @bInTagName = 0
						set @cTagPath = case when isnull(@cTagPath, '') <> '' then @cTagPath + '.' else '' end + @cTagName

						update #configFiles set tagKey = @cTagName where ukey = @nUkey
						update #configFiles set tagPath = @cTagPath where ukey = @nUkey and isnull(tagPath, '') = '' -- the line may continue, so set this now

						set @cTagPath = @cTagPath + case when isnull(@cTagFriendlyName, '') <> '' then '(' + replace(@cTagFriendlyName, '.', '') + ')' else '' end
					end

					if @bInComment = 1 and substring(@cTagString, @nCharacter, 3) = '-->'
					begin
						set @bInTag = 0
						set @cTagPath = left(@cTagPath, len(@cTagPath) - charindex('.', reverse(@cTagPath)))
						set @nCharacter = @nCharacter + 3
						set @bInComment = 0
					end

					if @cCharacter = '/' and @bInString = 0 and @bInComment = 0 -- and @bInTag = 1
						and (
							substring(@cTagString, @nCharacter, 2) = '/>'
							or substring(@cTagString, @nCharacter - 1, 2) = '</'
							)
					begin
						update #configFiles set tagPath = @cTagPath where ukey = @nUkey and isnull(tagPath, '') = '' -- the line may continue, so set this now

						set @bInTag = 0
						set @bInTagName = 0
						set @cTagPath = left(@cTagPath, len(@cTagPath) - charindex('.', reverse(@cTagPath)))
						set @nCharacter = 9000

					end
				end

				set @nCharacter = @nCharacter + 1
			end

			update #configFiles set tagPath = @cTagPath where ukey = @nUkey and isnull(tagPath, '') = ''
		end
	end

	--****************************************************************************************************************************************
	--****************************************************************************************************************************************
	-- Check for changes in config files since last check

	-- delete from configFileLog where fileString like '%locked out%'

	select
		servername, fileName,
		count(*) as numLines,
		sum(notification.dbo.fn_checksum(fileString)) as checksum
		into #checksum_current
		from #configFiles
		group by servername, fileName

	-- select * from #checksum_last where fileName = '\\web01\inetpub\sites\App_Nodes\App_Brand_Region\web.config'
	select
		a.servername, a.fileName,
		count(*) as numLines,
		sum(notification.dbo.fn_checksum(fileString)) as checksum,
		max(b.ymd) as ymd
		into #checksum_last
		from configFileLog a
		join (
			select servername, filename, max(ymd) as ymd
				from configFileLog (nolock)
				where ymd >= dateadd(day, -3, getDate())
				group by servername, fileName
			) b on a.filename = b.filename
			and a.servername = b.servername
			and a.ymd = b.ymd
		group by a.servername, a.fileName

	insert into notification.dbo.notificationLog_stage (serverName, ymd, subject, message, severity)
	select distinct
		a.servername,
		getDate(),
		'Config file ' + a.fileName + ' changed',
		a.filename + char(13) +
		'Checksum Now: ' + convert(varchar(20), isnull(checksum_current, 0)) + char(13) +
		'Checksum Last: ' + convert(varchar(20), isnull(checksum_last, 0)),
		1
		from (
			select
				distinct a.servername, a.filename, a.checksum as checksum_current, b.checksum as checksum_last
				from #checksum_current a
				left outer join #checksum_last b on a.filename = b.filename
					and a.servername = b.servername
				where isnull(a.checksum, 0) <> isnull(b.checksum, 0)
			union
			select
				distinct a.servername, a.filename, b.checksum as checksum_current, a.checksum as checksum_last
				from #checksum_last a
				left outer join #checksum_current b on a.filename = b.filename
					and a.servername = b.servername
				where isnull(a.checksum, 0) <> isnull(b.checksum, 0)
			) a

	-- create table configFileLog (ukey int identity, ymd dateTime default getDate(), servername varchar(100), filename varchar(500), fileString varchar(8000), tagPath varchar(2000), tagName varchar(500), tagKey varchar(2000))

	insert into configFileLog (ymd, servername, filename, filestring, tagpath, tagname, tagKey)
	select getdate(), servername, filename, filestring, tagpath, tagname, tagKey
		from #configFiles
		order by ukey

	--****************************************************************************************************************************************
	--****************************************************************************************************************************************
	-- Check for differences between servers which should match

	-- select top 500 * from notification.dbo.notificationLog order by ymd desc

	-- bindings
	insert into notification.dbo.notificationLog_stage (serverName, ymd, subject, message, severity)
	select
		a.servername,
		getDate(),
		case when b.nodeName <> a.nodeName then 'Mismatched' else 'Missing' end + ' Binding: ' + a.nodeName + ' (' + a.bindingURL + ') at ' + convert(varchar(16), getDate(), 120) as subject,
		'WEB34 has binding ' + a.bindingURL + ' on node ' + a.nodeName + ', ' + upper(a.servername) + ' does not. ' +
			case
				when b.nodeName <> a.nodeName then 'On ' + upper(a.servername) + ' this binding is on a different node: ' + b.nodeName
				else 'This binding does not exist at all on ' + upper(a.servername) + '.'
				end,
		2
		from (
			select distinct b.serverName, a.nodeName, a.tagName as bindingURL
				from (
					select distinct tagName, replace(replace(tagPath, '?xml.configuration.system.applicationHost.sites.site(', ''), ').bindings.binding', '') as nodeName
						from #configFiles
						where tagKey = 'binding'
							and not tagName like '%basichttpbinding%'
							and serverName = 'web34'	-- for now, this is the gold copy
					) a, (
					select distinct serverName
						from #configFiles
					) b
			) a
		left outer join (
			select *, replace(replace(tagPath, '?xml.configuration.system.applicationHost.sites.site(', ''), ').bindings.binding', '') as nodeName
				from #configFiles
			)  b on a.servername = b.servername
			and a.bindingURL = b.tagName

		where (b.servername is null or b.nodeName <> a.nodeName)
			and not a.serverName in ('web01')

		order by a.serverName, a.nodeName, a.bindingURL


	-- connection strings
	insert into notification.dbo.notificationLog_stage (serverName, ymd, subject, message, severity)
	select a.servername, getDate(),
		'Connection String ' + upper(a.nodeName) + '.' + a.tagName + ' is ' + case when b.sqlServer is null then 'MISSING' else upper(b.sqlServer) end + ' (WEB34 is ' + upper(a.sqlServer) + ') at ' + convert(varchar(16), getDate(), 120),
		'Connection String ' + upper(a.servername) + '.' + upper(a.nodeName) + '.' + a.tagName + ' is ' + case when b.sqlServer is null then 'MISSING' else upper(b.sqlServer) end + ' (WEB34 is ' + upper(a.sqlServer) + ')',
		2
		from (
			select distinct a.nodeName, a.tagName, a.sqlServer, b.serverName
				from (
					select *,
						replace(replace(substring(fileName, charindex('\sites\', fileName), 500), '\sites\', ''), '\web.config', '') as nodeName,
						replace(replace(replace(replace(
							left(
								substring(fileString, charindex('data source', fileString), 500),
								charindex(';', substring(fileString, charindex('data source', fileString), 500)) - 1
								), 'data source=', ''), 'tcp:', ''), ',1433', ''), ', 1433', '') as sqlServer
						from #configFiles
						where tagpath like '%connectionString%' and tagKey = 'Add'
							and serverName = 'web34'
							and not fileName like '%_old%'
							and not fileName like '%_backup%'
							and not fileName like '%_save%'
							and not fileName like '%AppSecure2%'
					) a, (select distinct servername from #configFiles) b
			) a
		left outer join (
			select *,
				replace(replace(substring(fileName, charindex('\sites\', fileName), 500), '\sites\', ''), '\web.config', '') as nodeName,
				replace(replace(replace(replace(
					left(
						substring(fileString, charindex('data source', fileString), 500),
						charindex(';', substring(fileString, charindex('data source', fileString), 500)) - 1
						), 'data source=', ''), 'tcp:', ''), ',1433', ''), ', 1433', '') as sqlServer
				from #configFiles
				where tagpath like '%connectionString%'
					and tagKey = 'Add'
			) b on a.servername = b.servername
				and a.nodeName = b.nodeName
				and a.tagName = b.tagName
		where not a.serverName in ('web01')
			and (
				b.servername is null
				or isnull(a.sqlServer, '') <> isnull(b.sqlServer, '')
				)





------4/13/2018 - susending these error by truncating  #tables
--truncate table #configFiles

--	insert into notification.dbo.notificationLog_stage (serverName, ymd, subject, message, severity)
--	select
--		'web02', getDate(),
--		'Tag ' + case when isnull(a.tagKey, '') <> '' then '"' + a.tagKey + case when isnull(a.tagname, '') <> '' and len(a.tagname) < 50 then ' : ' + a.tagName else '' end + '"' else case when isnull(a.tagname, '') <> '' and len(a.tagname) < 50 then a.tagName else '' end end + ' present on Web34 and missing on Web02 at ' + convert(varchar(20), getDate(), 120),
--		'Tag :' + a.tagPath + '<br>' +
--		'Tag Value: ' + replace(replace(a.fileString, '<', '&lt;'), '>', '&gt;') + '<br>' +
--		'Present on Web34 and missing on Web02',
--		3
----		, a.*
--		-- select a.*
--		from #configFiles a
--		left outer join #configFiles b on replace(a.filename, 'Web34', 'web02') = b.fileName
--			and replace(replace(a.tagpath, 'Web34', 'ServerName'), 'Web02', 'ServerName') = replace(replace(b.tagPath, 'Web34', 'ServerName'), 'Web02', 'ServerName')
--			and replace(replace(isnull(a.tagname, ''), 'Web34', 'ServerName'), 'Web02', 'ServerName') = replace(replace(isnull(b.tagname, ''), 'Web34', 'ServerName'), 'Web02', 'ServerName')
--			and replace(replace(a.fileString, 'Web34', 'ServerName'), 'Web02', 'ServerName') = replace(replace(b.fileString, 'Web34', 'ServerName'), 'Web02', 'ServerName')

--		where a.filename like '%Web34%'
--			and b.ukey is null
--			and a.fileName in (select distinct replace(a.filename, 'web02', 'Web34') from #configFiles where fileName like '%web02%')	-- make sure the file exists

--			and (
--				a.fileString like '%binding%'
--				or a.fileString like '%connection%'
--				)

--			and not (
--				a.fileString like '%applicationinsights%'
--				or a.fileString like '%projectguid%'
--				or a.fileString like '%projectguid%'
--				or a.fileString = '<!--'
--				or a.fileString = '-->'
--				)

--	insert into notification.dbo.notificationLog_stage (serverName, ymd, subject, message, severity)
--	select
--		'Web34', getDate(),
--		'Tag ' + case when isnull(a.tagKey, '') <> '' then '"' + a.tagKey + case when isnull(a.tagname, '') <> '' and len(a.tagname) < 50 then ' : ' + a.tagName else '' end + '"' else case when isnull(a.tagname, '') <> '' and len(a.tagname) < 50 then a.tagName else '' end end + ' present on Web34 and missing on Web02 at ' + convert(varchar(20), getDate(), 120),
--		'Tag :' + a.tagPath + '<br>' +
--		'Tag Value: ' + replace(replace(a.fileString, '<', '&lt;'), '>', '&gt;') + '<br>' +
--		'Present on Web02 and missing on Web34',
--		3
--		-- select a.*
--		from #configFiles a
--		left outer join #configFiles b on replace(a.filename, 'web02', 'Web34') = b.fileName
--			and replace(replace(a.tagpath, 'Web34', 'ServerName'), 'Web02', 'ServerName') = replace(replace(b.tagPath, 'Web34', 'ServerName'), 'Web02', 'ServerName')
--			and replace(replace(isnull(a.tagname, ''), 'Web34', 'ServerName'), 'Web02', 'ServerName') = replace(replace(isnull(b.tagname, ''), 'Web34', 'ServerName'), 'Web02', 'ServerName')
--			and replace(replace(a.fileString, 'Web34', 'ServerName'), 'Web02', 'ServerName') = replace(replace(b.fileString, 'Web34', 'ServerName'), 'Web02', 'ServerName')

--		where a.filename like '%web02%'
--			and b.ukey is null
--			and a.fileName in (select distinct replace(a.filename, 'Web34', 'web02') from #configFiles where fileName like '%Web34%')	-- make sure the file exists

--			and not (
--				a.fileString like '%applicationinsights%'
--				or a.fileString like '%projectguid%'
--				or a.fileString = '<!--'
--				or a.fileString = '-->'
--				)




	-- ***************************************************************************************************************************************************
	-- ***************************************************************************************************************************************************

--select top 100 * from #configFiles
--update #configFiles set fileString = 'Hello World' where ukey = 1516

	declare @nChangedLines int
	declare @nNewLines int
	declare @nDroppedLines int
	declare @cTo varchar(100)
	declare @cFrom varchar(100)
	declare @cSubject varchar(500)
	declare @cBody varchar(max)
	declare @nChangedFiles int

--	set @cTo = 'alerts@example.com'
	set @cTo = 'alerts@triplethreatsoftware.com'
	set @cFrom = 'alerts@example.com'


--	alter table #configFiles add lineNumber int

	-- select top 100 * from #configFiles order by ukey
	-- select top 100 * from audit..auditdata_config
	update #configFiles
		set lineNumber = a.ukey - b.minUkey + 1
		from #configFiles a
		join (
			select fileName, min(ukey) as minUkey
				from #configFiles
				group by fileName
			) b on a.fileName = b.fileName

	--set nocount off
	-- select * from #changedFiles
	-- drop table #changedFiles
	select a.servername, a.fileName, count(*) as changedLines
		into #changedFiles
		from #configFiles a
		left outer join audit..auditdata_config b on a.fileName = b.filePath
			and a.servername = b.servername
			and isnull(a.fileString, '') = isnull(b.fileString, '')
			and a.lineNumber = b.lineNumber
			and b.isCurrent = 1
		where b.ukey is null
			and not a.fileString like '%access is denied%'
			and not a.fileString like '%the network path was not found%'
			and not a.fileString like '%cannot find the path%'

			--and not b.fileString like '%access is denied%'
			--and not b.fileString like '%the network path was not found%'
			--and not b.fileString like '%cannot find the path%'

		group by a.servername, a.fileName

	-- select * from #changedFilesNewLines
	select a.fileName, a.lineNumber
		into #changedFilesNewLines
		from #configFiles a
		left outer join audit..auditdata_config b on a.fileName = b.filePath
			and a.servername = b.servername
			and isnull(a.fileString, '') = isnull(b.fileString, '')
			and b.isCurrent = 1
		where b.ukey is null
			and not a.fileString like '%access is denied%'
			and not a.fileString like '%the network path was not found%'
			and not a.fileString like '%cannot find the path%'

	-- select top 100 * from audit..auditdata_config
	-- select * from #changedFilesdroppedLines
	-- drop table #changedFilesdroppedLines
	select a.serverName, a.filePath, a.lineNumber
		into #changedFilesdroppedLines
		from audit..auditdata_config a
		left outer join #configFiles b on a.filePath = b.fileName
			and a.servername = b.servername
			and isnull(b.fileString, '') = isnull(a.fileString, '')
		join (select distinct serverName, fileName from #configFiles) c on a.servername = c.servername
			and a.filePath = c.fileName
		where b.ukey is null
			and a.isCurrent = 1
			and isnull(a.fileString, '') <> ''
			and not a.fileString like '%access is denied%'
			and not a.fileString like '%the network path was not found%'
			and not a.fileString like '%cannot find the path%'

	insert into #changedFiles (serverName, fileName, changedLines)
	select a.servername, a.filePath, numLines
		from (select serverName, filePath, count(*) as numLines from #changedFilesdroppedLines group by serverName, filePath) a
		left outer join #changedFiles b on a.filePath = b.fileName
			and a.servername = b.servername
		where b.fileName is null


	set @nChangedFiles = (select count(*) from #changedFiles)

	if isnull(@nChangedFiles, 0) > 20
	begin
--declare @cBody varchar(8000)
--declare @cServerName varchar(100) = 'web02'
--declare @nChangedFiles int = (select count(*) from #changedFiles)

		set @cBody = ''

		select @cBody = @cBody + fileName + ' (' + convert(varchar(20), changedLines) + ')<br>'
			from #changedFiles

		insert into notification.dbo.notificationLog_stage (servername, ymd, subject, message, severity, isConfiguration)
		select @cServerName, getDate(), convert(varchar(20), @nChangedFiles) + ' files changed', @cBody, 2, 1

	end
	else
	begin

		set @cfileName = ''

		while exists (select top 1 fileName from #changedFiles where fileName > @cfileName)
		begin
			select top 1
				@cfileName = fileName,
				@nChangedLines = changedLines
				from #changedFiles
				where fileName > @cfileName
				order by fileName

			select top 1
				@nNewLines = count(*)
				from #changedFilesNewLines
				where fileName = @cfileName

			select top 1
				@nDroppedLines = count(*)
				from #changedFilesDroppedLines
				where filePath = @cfileName

			set @cBody = ''
			set @nChangedLines = isnull(@nChangedLines, 0)
			set @nNewLines = isnull(@nNewLines, 0)
			set @nDroppedLines = isnull(@nDroppedLines, 0)

			if @nChangedLines <= 20
			begin

				select @cBody = @cBody +
	'LINE ' + convert(varchar(20), lineNumber) + '
		NEW: ' + isnull(fileString_new, '') + '
		OLD: ' + isnull(fileString_old, '') + char(13) + char(13)
					from (
						select top 20
							a.lineNumber,
							replace(a.fileString, char(9), '') as fileString_new,
							replace(b.fileString, char(9), '') as fileString_old
							from #configFiles a
							left outer join audit..auditdata_config b on a.fileName = b.filePath
								and a.lineNumber = b.lineNumber
								and b.isCurrent = 1
							where not (isnull(a.fileString, '') = isnull(b.fileString, ''))
								and a.fileName = @cfileName
							order by a.lineNumber
						) a

				select @cBody = @cBody +
	'LINE ' + convert(varchar(20), lineNumber) + '
		NEW: [LINE REMOVED]
		OLD: ' + isnull(fileString_old, '') + char(13) + char(13)

					from (
						select top 20 a.lineNumber, replace(b.fileString, char(9), '') as fileString_new, replace(a.fileString, char(9), '') as fileString_old
							from audit..auditdata_config a
							left outer join #configFiles b on a.filePath = b.fileName
								and a.lineNumber = b.lineNumber
							where a.isCurrent = 1
								and b.fileName is null
								and a.filePath = @cfileName
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
		' + isnull(fileString, '') + char(13) + char(13)
					from (
						select top 20
							a.lineNumber,
							replace(a.fileString, char(9), '') as fileString
							from #configFiles a
							join #changedFilesNewLines b on a.lineNumber = b.linenumber
								and b.fileName = a.fileName
							where a.fileName = @cfileName
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
							from audit..auditdata_config a
							join #changedFilesDroppedLines b on a.lineNumber = b.linenumber
								and b.filePath = a.filePath
							where a.isCurrent = 1
								and a.filePath = @cfileName
							order by a.lineNumber
						) a
				end

				if isnull(@cBody, '') = ''
					set @cBody = convert(varchar(20), @nChangedLines) + ' lines changed in file ' + @cfileName
			end

			set @cSubject = '[' + convert(varchar(20), @nChangedLines) + ' lines changed] ' + @cfileName

			set @cBody = @cBody + char(13) + char(13) +
				'Scan date: ' + convert(varchar(20), getDate(), 120)

			--print @cSubject
			--print @cBody

			-- exec notification.dbo.pr_sendMessage @cFrom, 'alerts@example.com', @cSubject, @cBody, 0
			exec notification.dbo.pr_sendMessage @cFrom, @cTo, @cSubject, @cBody, 0
		end
	end

	update audit..auditdata_config
		set isCurrent = 0
		-- select *
		from audit..auditdata_config a
		join #changedFiles b on a.filePath = b.fileName
			and a.servername = b.serverName
		where a.isCurrent = 1

	-- select top 100 * from audit..auditdata_config
	-- declare @cServerName varchar(100) = 'web0w'
	insert into audit..auditdata_config (servername, filePath, filestring, iscurrent, linenumber)
	select a.servername, a.fileName, a.fileString, 1, a.lineNumber
		from #configFiles a
		join #changedFiles b on a.fileName = b.fileName
		order by a.fileName, a.ukey

	drop table #changedFiles
	drop table #changedFilesNewLines
	drop table #changedFilesDroppedLines


	-- ***************************************************************************************************************************************************
	-- ***************************************************************************************************************************************************

	drop table #directories
	drop table #configFiles
end
