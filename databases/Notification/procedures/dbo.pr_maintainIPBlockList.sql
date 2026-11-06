/****** Object:  StoredProcedure [dbo].[pr_maintainIPBlockList]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_maintainIPBlockList]
as
begin
	-- return

	declare @cSQLString nvarchar(4000)
	declare @cSubject varchar(500)
	declare @cBody varchar(max)

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- Malicious UserAgents

	update weblogs.dbo.dm_useragent
		set isMalicious = 1
		where isMalicious = 0
			and (
				left(userAgent, 1) in ('''')
				or userAgent like '% union %'
				)

	if object_id('tempdb..#useragents') is not null
		drop table #useragents

	-- select * from #useragents
	select
		c.clientIP,
		count(*) as numRequests,
		min(d.uriStem + case when isnull(a.querystring, '') <> '-' then isnull('?' + a.querystring, '') else '' end) as ex1,
		max(d.uriStem + case when isnull(a.querystring, '') <> '-' then isnull('?' + a.querystring, '') else '' end) as ex2,
		min(a.ymd) as minYMD,
		max(a.ymd) as maxYMD,
		min(b.userAgent) as minAgent,
		max(b.userAgent) as maxAgent
		into #useragents
		-- select *
		from weblogs.dbo.v_fact_weblogs_all a (nolock)
		join weblogs.dbo.dm_useragent b (nolock) on a.ukey_userAgent = b.ukey
			and b.isMalicious = 1
		join weblogs.dbo.dm_clientIP c (nolock) on a.ukey_clientIP = c.ukey
		join weblogs.dbo.dm_uristem d (nolock) on a.ukey_uriStem = d.ukey
		where ymd >= dateadd(week, -3, getDate())
		group by c.clientIP
		order by max(ymd) desc

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- SQL brute force attacks

	if object_id('tempdb..#hackattempts') is not null
		drop table #hackattempts

	-- select * from #hackattempts
	select
		rtrim(ltrim(replace(replace(substring(logMessage, charindex('CLIENT:', logMessage), 100), 'CLIENT: ', ''), ']', ''))) as ipAddress,
		count(*) as numAttempts,
		min(ymd) as minYMD,
		max(ymd) as maxYMD
		into #hackattempts
		-- select *
		from sqlErrorLog  (nolock)
		where logMessage like '%login failed%'
			--and not logMessage like '%could not find a login%'
			--and not logMessage like '%password did not match%'
			and ymd >= dateadd(week, -3, getDate())
		group by rtrim(ltrim(replace(replace(substring(logMessage, charindex('CLIENT:', logMessage), 100), 'CLIENT: ', ''), ']', '')))
		order by max(ymd) desc

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- catalog all requested pages

	--if object_id('tempdb..#maliciousURIStems') is not null
	--	drop table #maliciousURIStems

	--select distinct ukey_uriStem, ukey_site, convert(bit, 1) as isMalicious
	--	into #maliciousURIStems
	--	from weblogs.dbo.v_fact_weblogs_all a (nolock)
	--	where a.ymd >= dateadd(week, -3, getDate())

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************

--	if object_id('tempdb..#filesToImport') is not null
--		drop table #filesToImport

--	create table #filesToImport (ukey int identity, dirString varchar(500), fileName varchar(500), directory varchar(500), filePath varchar(500), fileDate dateTime, fileSize bigint, dirGUID uniqueIdentifier)
--	create clustered index ix_tmp_filesToImport_ukey on #filesToImport (ukey) with fillfactor = 60

--	exec weblogs.dbo.pr_recurseDirectories '\\web02\c$\inetpub'

--	delete from #filesToImport where not directory like '%wwwroot%'
--	delete from #filesToImport where fileName like '%.config'
--	delete from #filesToImport where fileName like '%.vb'
--	delete from #filesToImport where fileName like '%.cs'
--	delete from #filesToImport where fileName like '%.cache'
--	delete from #filesToImport where fileName like '%.dll'
--	delete from #filesToImport where fileName like '%.pdb'
--	delete from #filesToImport where fileName like '%.log'
--	delete from #filesToImport where fileName like '%.json'
--	delete from #filesToImport where fileName like '%.sln'
--	delete from #filesToImport where fileName like '%.lst'
--	delete from #filesToImport where fileName like '%csproj%'
--	delete from #filesToImport where fileName like '%.master'
--	delete from #filesToImport where fileName like '%.editorconfig'
--	delete from #filesToImport where fileName in ('apphost.exe')
--	delete from #filesToImport where fileSize = 0

--	delete from #filesToImport where fileName is null

--	--select replace(replace(filePath, '\\web02\c$\inetpub', ''), '\', '/'), * from #filesToImport

--	update #maliciousURIStems
--		set isMalicious = 0
--		from #maliciousURIStems a
--		join weblogs.dbo.dm_uriStem b (nolock) on a.ukey_uristem = b.ukey
--		join #filesToImport c on b.uriStem = replace(replace(replace(replace(replace(replace(replace(replace(replace(
--			c.filePath, '\\web02\c$\inetpub\wwwroot_triplethreatsoftware\', '/'),
--			'\\web02\c$\inetpub\wwwroot_simpledance\', '/'),
--			'\\web02\c$\inetpub\wwwroot_sqlbeat\', '/'),
--			'\\web02\c$\inetpub\wwwroot_sqlbeat_api\', '/'),
--			'\\web02\c$\inetpub\wwwroot_sqlfed\', '/'),
--			'\\web02\c$\inetpub\wwwroot_sqlbeatdev\', '/'),
--			'\\web02\c$\inetpub\wwwroot_shopdap\', '/'),
--			'\\web02\c$\inetpub\wwwroot_itchycody\', '/'),
--			'\', '/')
--		join weblogs.dbo.dm_sites d (nolock) on a.ukey_site = d.ukey
--		where (filePath like '\\web02\c$\inetpub\wwwroot\%' and d.webserverservice = 'w3svc1')
--			or (filePath like '\\web02\c$\inetpub\wwwroot_triplethreatsoftware\%' and d.webserverservice = 'w3svc2')
--			or (filePath like '\\web02\c$\inetpub\wwwroot_simpledance\%' and d.webserverservice = 'w3svc3')
--			or (filePath like '\\web02\c$\inetpub\wwwroot_sqlbeat\%' and d.webserverservice = 'w3svc4')
--			--or (filePath like '\\web02\c$\inetpub\wwwroot_\%' and d.webserverservice = 'w3svc5')
--			--or (filePath like '\\web02\c$\inetpub\wwwroot_\%' and d.webserverservice = 'w3svc6')
--			or (filePath like '\\web02\c$\inetpub\wwwroot_sqlbeat_api\%' and d.webserverservice = 'w3svc7')
--			or (filePath like '\\web02\c$\inetpub\wwwroot_sqlfed\%' and d.webserverservice = 'w3svc8')
--			or (filePath like '\\web02\c$\inetpub\wwwroot_sqlbeatdev\%' and d.webserverservice = 'w3svc9')
--			--or (filePath like '\\web02\c$\inetpub\wwwroot_\%' and d.webserverservice = 'w3svc10')
--			or (filePath like '\\web02\c$\inetpub\wwwroot_shopdap\%' and d.webserverservice = 'w3svc11')
--			--or (filePath like '\\web02\c$\inetpub\wwwroot_\%' and d.webserverservice = 'w3svc12')
--			or (filePath like '\\web02\c$\inetpub\wwwroot_itchycody\%' and d.webserverservice = 'w3svc13')

--	update #maliciousURIStems
--		set isMalicious = 0
--		from #maliciousURIStems a
--		join weblogs.dbo.dm_uriStem b (nolock) on a.ukey_uristem = b.ukey
--		where uriStem = '/'
--			or uriStem like '/.well-known/%'
--			or uriStem like '%.png'
--			or uriStem like '%.jpg'
--			or uriStem like '%.gif'
--			or uriStem like '%.pdf'
--			or uriStem like '%.ico'
--			or (uriStem like '/products/%' and ukey_site = 10)
--			or uriStem in ('/about-studio-manager-backup-and-networking.aspx', '/about-studio-manager-classes.aspx', '/about-studio-manager-inventory.aspx',  '/about-studio-manager-reporting.aspx',
--					'/about-studio-manager-sessions.aspx', '/about-studio-manager-students-and-families.aspx', '/about-studio-manager-vendors-and-costumes.aspx', '/about-studio-manager.aspx',
--					'/aboutus.aspx', '/robots.txt', '/webresource.axd', '/ScriptResource.axd', '/sitemap.xml', '/index.html', '/index.htm', '/default.aspx', '/sitemap.txt', '/sitemap', '/news.html',
--					'/ads.txt', '/sql-server-database-monitoring/user-defined-alerts-and-dashboards.aspx', '/styles.css', '/faq.aspx', '/sitemaps.xml', '/services.html', '/blog.html',
--					'/sql-server-database-monitoring/sql-monitoring.aspx', '/newuser.aspx', '/ER.html', '/basicRC.html', '/apple-app-site-association', '/login.aspx', '/sitemap_index.xml')

----	select uriStem, count(distinct ukey_site) as numSites
----		from #maliciousURIStems a
----		join weblogs.dbo.dm_uristem b on a.ukey_uristem = b.ukey
----		where isMalicious = 1
------			and uristem = '/assets/favicon.png'
----		group by uriStem
----		order by uriStem

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- malicious weblog requests

	if object_id('tempdb..#maliciousrequests') is not null
		drop table #maliciousrequests

	select
		b.clientIP as ipAddress,
		count(*) as numAttempts,
		min(ymd) as minYMD,
		max(ymd) as maxYMD,
		max(c.uriStem) as maxURI,
		max(a.queryString) as maxQuerystring
		into #maliciousRequests
		from weblogs.dbo.v_fact_weblogs_all a (nolock)
		join weblogs.dbo.dm_clientIP b (nolock) on a.ukey_clientIP = b.ukey
		join weblogs.dbo.dm_uriStem c (nolock) on a.ukey_uriStem = c.ukey

		--join #maliciousURIStems d on a.ukey_site = d.ukey_site
		--	and a.ukey_uriStem = d.ukey_uriStem

		where a.ymd >= dateadd(week, -3, getDate())
			and (
				--d.isMalicious = 1
				--or
				 (
					c.uriStem like '%.php'
					or c.uriStem like '%wp-includes%'
					or c.uriStem like '%/wp%'
					or c.uriStem like '%wordpress%'
					or c.uriStem like '%geoserver%'
					or c.uriStem like '%cgi-bin%'
					or c.uriStem like '%sysdate%'
					or c.uriStem like '%sleep%'
					or charindex('xor', c.uristem) > 0
					or charindex('../', a.querystring) > 0
					or charindex('array', a.querystring) > 0
					or charindex('function', a.querystring) > 0
					or charindex('php:', a.querystring) > 0
					or charindex('action=', a.querystring) > 0
					or charindex('username', a.querystring) > 0

					or (
						(a.requestStatus = '404' or a.requestStatus like '5%')
						and (
							c.uristem like '%login%'
							or c.uristem like '%/app/%'
							)
						)
					)
				)
		group by b.clientIP
		order by max(ymd) desc

--select * from #hackattempts where ipAddress like '10.%' or ipAddress like '172.%' or ipAddress like '192.168%'
--select * from #maliciousRequests where ipAddress = '34.1.20.172'
--select * from #useragents where clientIP like '10.%' or clientIP like '172.%' or clientIP like '192.168%'


	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- combine the two

	if object_id('maliciousIPs') is not null
	begin
		if object_id('maliciousIPs_old') is not null
			drop table maliciousIPs_old

		select * into maliciousIPs_old from maliciousIPs

		drop table maliciousIPs
	end

	create table maliciousIPs (ipAddress varchar(100), minYMD dateTime, maxYMD dateTime, example1 varchar(8000), example2 varchar(8000))

	-- select * from maliciousIPs where ipaddress in ('15.235.96.224', '54.39.6.249') order by ipAddress
	insert into maliciousIPs (ipAddress, minYMD, maxYMD, example1, example2)
	select ipAddress,
		min(minYMD) as minYMD,
		max(maxYMD) as maxYMD,
		max(example1) as example1,
		max(example2) as example2
		from (
			select ipAddress, minYMD, maxYMD, convert(varchar(8000), null) as example1, convert(varchar(8000), null) as example2
				from #hackattempts
			union
			select ipaddress, minYMD, maxYMD, maxURI, maxQuerystring
				from #maliciousRequests
			union
			select clientIP, minYMD, maxYMD, minAgent, maxAgent
				from #useragents
			) a
		where dbo.fn_occurs('.', ipAddress) = 3
		group by ipAddress


	-- ********************************************************************************************************************
	-- ********************************************************************************************************************

	-- ensure we are not blocking GoogleBot or BingBot or our IP
	delete
		-- select *
		from maliciousIPs
		where ipaddress like '%66.249.%'
			or ipaddress like '%40.91.82%'
			or ipaddress like '%13.86.97%'
			or ipaddress like '%13.86.98%'
			or ipaddress like '%23.100.224%'
			or ipaddress like '%23.100.225%'
			or ipaddress like '%20.45.5.%'
			or ipaddress like '%20.42.35.%'
			or ipaddress = '73.237.69.56'
			-- make sure we don't block ourselves
			or ipaddress like '10.%'
			or ipaddress like '192.168.%'
			or ipaddress like '172.16.%'
			or ipaddress like '172.17.%'
			or ipaddress like '172.18.%'
			or ipaddress like '172.19.%'
			or ipaddress like '172.20.%'
			or ipaddress like '172.21.%'
			or ipaddress like '172.22.%'
			or ipaddress like '172.23.%'
			or ipaddress like '172.24.%'
			or ipaddress like '172.25.%'
			or ipaddress like '172.26.%'
			or ipaddress like '172.27.%'
			or ipaddress like '172.28.%'
			or ipaddress like '172.29.%'
			or ipaddress like '172.30.%'
			or ipaddress like '172.31.%'

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************

	update weblogs.dbo.dm_clientIP
		set isBlocked = 1
		from weblogs.dbo.dm_clientIP a
		join maliciousIPs b (nolock) on a.clientIP = b.ipAddress

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- send alerts

	if object_id('maliciousIPs_old') is not null
	begin
		declare @nRowCount int

		set @nRowCount = (
			select count(*)
				from maliciousIPs a
				left outer join maliciousIPs_old b on a.ipAddress = b.ipAddress
				where b.ipAddress is null
			)

		if @nRowCount > 10
		begin
			set @cSubject = convert(varchar(20), @nRowCount) + ' IPs Blocked @ ' + convert(varchar(20), getDate(), 120)
			set @cBody = ''

			select @cBody = @cBody + a.ipAddress + '<br>'
				from (
					select top 1000 a.ipAddress
						from maliciousIPs a
						left outer join maliciousIPs_old b on a.ipAddress = b.ipAddress
						where b.ipAddress is null
						order by a.ipAddress
					) a

			insert into notification.dbo.notificationLog_stage (serverName, severity, subject, message) values (@@servername, 3, @cSubject, left(@cBody, 8000))
		end
		else
		begin
			insert into notification.dbo.notificationLog_stage (serverName, severity, subject, message)
			select @@servername, 3,
				'IP Blocked: ' + a.ipAddress,
				'IP Blocked: ' + a.ipAddress + '<br>' +
					'Min YMD: ' + convert(varchar(20), a.minYMD, 120) + '<br>' +
					'Max YMD: ' + convert(varchar(20), a.minYMD, 120) + '<br>' +
					'Example1: ' + a.example1 + '<br>' +
					'Example2: ' + a.example2
				from maliciousIPs a
				left outer join maliciousIPs_old b on a.ipAddress = b.ipAddress
				where b.ipAddress is null
		end
	end

	-- select top 1000 * from notificationLog where subject like 'ip blocked%' order by ymd desc

--	-- ********************************************************************************************************************
--	-- ********************************************************************************************************************
--	-- Setup

--	create table #output (wideString varchar(max), ukey int identity)
--	create clustered index ix_output_ukey on #output (ukey) with fillfactor = 60

--	-- ********************************************************************************************************************
--	-- ********************************************************************************************************************
--	-- create a file to be read by PFBlocker

--	set @cSQLString = 'bcp "select distinct ipAddress from notification.dbo.maliciousIPs order by ipAddress" queryout "\\web02\wwwroot_sqlbeat\blocklist_malicious.txt" -c -T -r \n'

--	truncate table #output
--	insert into #output (wideString)
--	exec master..xp_cmdshell @cSQLString

--	if (select count(*) from #output where widestring like '%error%') > 0
--	begin
--		select * from #output

--		set @cSubject = 'pr_maintainIPBlockList - Error writing block list @ ' + convert(varchar(20), getDate(), 120)
--		set @cBody = ''

--		select @cBody = @cBody + wideString + '<br>'
--			from #output
--			where wideString is not null
--				and wideString <> ''
----			where wideString like '%error%'

--		insert into notification.dbo.notificationLog_stage (serverName, severity, subject, message) values (@@servername, 2, @cSubject, @cBody)
--		print @cSubject
--		print @cBody
--	end

--	-- ********************************************************************************************************************
--	-- ********************************************************************************************************************
--	-- initiate a refresh of PFBlocker

	--declare @cScriptPath varchar(2000)

	--if not exists (select top 1 ukey from notification.dbo.dm_settings where settingName = 'shared folder')
	--	insert into notification.dbo.dm_settings (settingName, settingValue) values ('shared folder', 'C:\SHARED\')

	--set @cScriptPath = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'shared folder')

	--if right(@cScriptPath, 1) <> '\'
	--	set @cScriptPath = @cScriptPath + '\'

--	set @cSQLString = 'powershell -file ' + @cScriptPath + 'pfsense_pfblocker_refresh_pf03.ps1'

--	truncate table #output
--	insert into #output (wideString)
--	exec master..xp_cmdshell @cSQLString

--	if not exists (select top 1 widestring from #output where widestring = 'pfBlocker successfully updated')
--	--(select count(*) from #output where widestring like '%pfBlockerNG already running%') = 0
--	--	and (select count(*) from #output where widestring like '%pfBlocker successfully updated%') = 0
--	--	and (select count(*) from #output where widestring like '%has timed out%') = 0
--	begin
--		set @cSubject = 'pr_maintainIPBlockList - Error triggering PFBlockerNG refresh @ ' + convert(varchar(20), getDate(), 120)
--		set @cBody = ''

--		select @cBody = @cBody + wideString + '<br>'
--			from #output
--			where wideString is not null
----			where wideString like '%error%'

--		insert into notification.dbo.notificationLog_stage (serverName, severity, subject, message) values (@@servername, 3, @cSubject, @cBody)
--		print @cSubject
--		print @cBody
--	end

	--drop table #output

--	select * from maliciousIPs where ipAddress in ('99.116.182.177', '97.81.66.55', '99.146.23.44', '172.11.249.190')

end
GO
