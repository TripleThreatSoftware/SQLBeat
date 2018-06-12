USE [Configuration]
GO
/****** Object:  StoredProcedure [dbo].[pr_monitorConfigurationFiles]    Script Date: 6/12/2018 4:16:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER procedure [dbo].[pr_monitorConfigurationFiles]
as
begin

	delete from configFileLog where ymd < dateadd(day, -60, getDate())

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
	create table #configFiles (ukey int identity, fileName varchar(2000), fileString varchar(8000), tagPath varchar(8000), ukey_parent int, tagName varchar(500), tagKey varchar(500), servername varchar(100))

	create clustered index ix_configfiles_ukey on #configFiles (ukey) with fillfactor = 80

	declare @servers table (servername varchar(100))
--	insert into @servers (servername) values ('web01')
	insert into @servers (servername) values ('web02')

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

		set @cSQLString = 'type \\' + @cServerName + '\c$\windows\system32\inetsrv\config\administration.config'

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

		set @cSQLString = 'type \\' + @cServerName + '\c$\windows\system32\inetsrv\config\redirection.config'

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

	select
		servername, fileName,
		count(*) as numLines,
		sum(notification.dbo.fn_checksum(fileString)) as checksum
		into #checksum_current
		from #configFiles
		group by servername, fileName

	select
		a.servername, a.fileName,
		count(*) as numLines,
		sum(notification.dbo.fn_checksum(fileString)) as checksum
		into #checksum_last
		from configFileLog a
		join (
			select servername, filename, max(ymd) as ymd
				from configFileLog
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

	--****************************************************************************************************************************************
	--****************************************************************************************************************************************
	-- Check for differences between servers which should match
--4/13/2018 - susending these error by truncating  #tables
truncate table #configFiles

	insert into notification.dbo.notificationLog_stage (serverName, ymd, subject, message, severity)
	select
		'web02', getDate(),
		'Tag ' + case when isnull(a.tagKey, '') <> '' then '"' + a.tagKey + case when isnull(a.tagname, '') <> '' and len(a.tagname) < 50 then ' : ' + a.tagName else '' end + '"' else case when isnull(a.tagname, '') <> '' and len(a.tagname) < 50 then a.tagName else '' end end + ' present on Web01 and missing on Web02 at ' + convert(varchar(20), getDate(), 120),
		'Tag :' + a.tagPath + '<br>' +
		'Tag Value: ' + replace(replace(a.fileString, '<', '&lt;'), '>', '&gt;') + '<br>' +
		'Present on Web01 and missing on Web02',
		1
--		, a.*
		-- select a.*
		from #configFiles a
		left outer join #configFiles b on replace(a.filename, 'web01', 'web02') = b.fileName
			and replace(replace(a.tagpath, 'WEB01', 'ServerName'), 'Web02', 'ServerName') = replace(replace(b.tagPath, 'WEB01', 'ServerName'), 'Web02', 'ServerName')
			and replace(replace(isnull(a.tagname, ''), 'WEB01', 'ServerName'), 'Web02', 'ServerName') = replace(replace(isnull(b.tagname, ''), 'WEB01', 'ServerName'), 'Web02', 'ServerName')
			and replace(replace(a.fileString, 'WEB01', 'ServerName'), 'Web02', 'ServerName') = replace(replace(b.fileString, 'WEB01', 'ServerName'), 'Web02', 'ServerName')

		where a.filename like '%web01%'
			and b.ukey is null

			and not (
				a.fileString like '%applicationinsights%'
				or a.fileString = '<!--'
				or a.fileString = '-->'
				)

	insert into notification.dbo.notificationLog_stage (serverName, ymd, subject, message, severity)
	select
		'web01', getDate(),
		'Tag ' + case when isnull(a.tagKey, '') <> '' then '"' + a.tagKey + case when isnull(a.tagname, '') <> '' and len(a.tagname) < 50 then ' : ' + a.tagName else '' end + '"' else case when isnull(a.tagname, '') <> '' and len(a.tagname) < 50 then a.tagName else '' end end + ' present on Web01 and missing on Web02 at ' + convert(varchar(20), getDate(), 120),
		'Tag :' + a.tagPath + '<br>' +
		'Tag Value: ' + replace(replace(a.fileString, '<', '&lt;'), '>', '&gt;') + '<br>' +
		'Present on Web02 and missing on Web01',
		1
		-- select a.*
		from #configFiles a
		left outer join #configFiles b on replace(a.filename, 'web02', 'web01') = b.fileName
			and replace(replace(a.tagpath, 'WEB01', 'ServerName'), 'Web02', 'ServerName') = replace(replace(b.tagPath, 'WEB01', 'ServerName'), 'Web02', 'ServerName')
			and replace(replace(isnull(a.tagname, ''), 'WEB01', 'ServerName'), 'Web02', 'ServerName') = replace(replace(isnull(b.tagname, ''), 'WEB01', 'ServerName'), 'Web02', 'ServerName')
			and replace(replace(a.fileString, 'WEB01', 'ServerName'), 'Web02', 'ServerName') = replace(replace(b.fileString, 'WEB01', 'ServerName'), 'Web02', 'ServerName')

		where a.filename like '%web02%'
			and b.ukey is null

			and not (
				a.fileString like '%applicationinsights%'
				or a.fileString = '<!--'
				or a.fileString = '-->'
				)

	drop table #directories
	drop table #configFiles
end
