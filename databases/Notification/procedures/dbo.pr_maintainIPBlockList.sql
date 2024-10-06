CREATE procedure [dbo].[pr_maintainIPBlockList]
as
begin

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- SQL brute force attacks

	if object_id('tempdb..#hackattempts') is not null
		drop table #hackattempts

	select
		rtrim(ltrim(replace(replace(substring(logMessage, charindex('CLIENT:', logMessage), 100), 'CLIENT: ', ''), ']', ''))) as ipAddress,
		count(*) as numAttempts,
		min(ymd) as minYMD,
		max(ymd) as maxYMD
		into #hackattempts
		from sqlErrorLog
		where logMessage like '%login failed%'
			and ymd >= dateadd(week, -1, getDate())
		group by rtrim(ltrim(replace(replace(substring(logMessage, charindex('CLIENT:', logMessage), 100), 'CLIENT: ', ''), ']', '')))
		order by max(ymd) desc

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- malicious weblog requests

	if object_id('tempdb..#maliciousrequests') is not null
		drop table #maliciousrequests

	select b.clientIP as ipAddress,
		count(*) as numAttempts,
		min(ymd) as minYMD,
		max(ymd) as maxYMD,
		max(c.uriStem) as maxURI,
		max(a.queryString) as maxQuerystring
		into #maliciousRequests
		from weblogs.dbo.v_fact_weblogs_all a (nolock)
		join weblogs.dbo.dm_clientIP b (nolock) on a.ukey_clientIP = b.ukey
		join weblogs.dbo.dm_uriStem c (nolock) on a.ukey_uriStem = c.ukey

		where a.ymd >= dateadd(week, -1, getDate())
			and not c.uriStem in ('/', '/contact.html', '/purchase.aspx', '/contact.aspx', '/modules.aspx', '/robots.txt', '/ads.txt', '/CSS/navigation.css', '/CSS/index.css', '/files/case-study-georgia-department-of-education.pdf',
				'/case-study-georgia-department-of-education.pdf', '/case-studies.aspx', '/assets/favicon.png', '/css/styles.css', '/how_it_works.html', '/assets/logo_sqlbeat.gif', '/assets/gradient-background.gif',
				'/case_studies.html', '/assets/topology1.png', '/assets/topology2.png', '/pricing.html', '/studiomanager.ver', '/connectionsettings.htm')

			and (
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
				)
		group by b.clientIP
		order by max(ymd) desc

	--select * from #maliciousRequests


	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- combine the two

	if object_id('maliciousIPs') is not null
		drop table maliciousIPs

	create table maliciousIPs (ipAddress varchar(100))

	insert into maliciousIPs (ipAddress)
	select distinct ipAddress
		from (
			select distinct ipAddress
				from #hackattempts
			union
			select distinct ipaddress
				from #maliciousRequests
			) a
		where dbo.fn_occurs('.', ipAddress) = 3

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
			or ipaddress like '10.10.10%'
			or ipaddress like '192.168.%'

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- Setup

	declare @cSQLString nvarchar(4000)
	declare @cSubject varchar(500)
	declare @cBody varchar(max)
	create table #output (wideString varchar(max), ukey int identity)
	create clustered index ix_output_ukey on #output (ukey) with fillfactor = 60

	-- ********************************************************************************************************************
	-- ********************************************************************************************************************
	-- create a file to be read by PFBlocker

	set @cSQLString = 'bcp "select distinct ipAddress from notification.dbo.maliciousIPs order by ipAddress" queryout "\\web02\c$\inetpub\wwwroot_sqlbeat\blocklist_malicious.txt" -c -T -r \n'

	truncate table #output
	insert into #output (wideString)
	exec master..xp_cmdshell @cSQLString

	if (select count(*) from #output where widestring like '%error%') > 0
	begin
		set @cSubject = 'pr_maintainIPBlockList - Error writing block list @ ' + convert(varchar(20), getDate(), 120)
		set @cBody = ''

		select @cBody = @cBody + wideString + '<br>'
			from #output
--			where wideString like '%error%'

		insert into notification.dbo.notificationLog_stage (serverName, severity, subject, message) values (@@servername, 2, @cSubject, @cBody)
		print @cSubject
		print @cBody
	end

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

	drop table #output

end
GO
