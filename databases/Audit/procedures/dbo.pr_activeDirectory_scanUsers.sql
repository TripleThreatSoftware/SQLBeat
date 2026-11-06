-- ================================================================================================
-- Audit.dbo.pr_activeDirectory_scanUsers
--
-- Runs the ad_users_last60 and ad_computers_last60 PowerShell scripts against an AD server and
-- stores the results in auditData_activeDirectory. Job: "Monitor Active Directory".
-- ================================================================================================
/****** Object:  StoredProcedure [dbo].[pr_activeDirectory_scanUsers]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select top 100 * from auditData_activeDirectory order by ukey desc
CREATE procedure [dbo].[pr_activeDirectory_scanUsers]
as

begin

	--create table auditData_activeDirectory (serverName varchar(100), ymd dateTime default getDate(), ukey int identity, objectName varchar(500), keyName varchar(500), keyValue varchar(8000), ymd_lastSeen dateTime, isCurrent bit)
	--go


	-- drop table #results
	create table #results (ukey int identity, wideString varchar(8000), ukey_parent int, keyName varchar(500), keyValue varchar(2000), objectName varchar(500))


	create clustered index ix_tmp_results_ukey on #results (ukey) with fillfactor = 80

	declare @cSQLString nvarchar(4000)

	-- ************************************************************************************************************************************************************************
	-- ************************************************************************************************************************************************************************

	-- insert results for USERS
	set @cSQLString = 'powershell -file c:\shared\ad_users_last60.ps1 -cServerName 10.10.10.201 -cUserName "CORP\MonitoringService" -cPassword "REDACTED"'

	insert into #results (wideString)
	exec master..xp_cmdshell @cSQLString

	-- insert results for COMPUTERS
	set @cSQLString = 'powershell -file c:\shared\ad_computers_last60.ps1 -cServerName 10.10.10.201 -cUserName "CORP\MonitoringService" -cPassword "REDACTED"'

	insert into #results (wideString)
	exec master..xp_cmdshell @cSQLString

	-- ************************************************************************************************************************************************************************
	-- ************************************************************************************************************************************************************************
	-- normal processing

	update #results
		set keyName = left(wideString, charindex(' ', wideString))
		where left(wideString, 1) <> ''
			and isnull(wideString, '') <> ''


	declare @nRowCount int

	set @nRowCount = 1

	while @nRowCount > 0
	begin
		update a
			set keyName = b.keyName
			from #results a
			join #results b on b.ukey = a.ukey - 1
			where a.keyName is null
				and b.keyName is not null
				and not a.wideString is null

		set @nRowCount = @@ROWCOUNT
	end

	update #results
		set keyValue = rtrim(ltrim(substring(widestring, charindex(' : ', widestring) + 2, 8000)))

	update #results
		set ukey_parent = b.ukey_parent
		from #results a
		join (
			select a.ukey, max(b.ukey) as ukey_parent
				from #results a
				join #results b on b.ukey <= a.ukey
				where b.keyName = 'AccountExpirationDate'
				group by a.ukey
			) b on a.ukey = b.ukey

	set @nRowCount = 1

	while @nRowCount > 0
	begin

		update a
			set keyValue = a.keyValue + ' ' + b.keyValue
			from #results a
			join #results b on a.keyName = b.keyName
				and a.ukey_parent = b.ukey_parent
			join (select ukey_parent, keyName, min(ukey) as minUkey from #results group by ukey_parent, keyName) x on a.ukey_parent = x.ukey_parent
				and a.keyName = x.keyName
				and a.ukey = x.minUkey
			join (select ukey_parent, keyName, min(ukey) as minUkey from #results where not wideString like keyName + '%' group by ukey_parent, keyName) y on a.ukey_parent = y.ukey_parent
				and a.keyName = y.keyName
				and b.ukey = y.minUkey
			where not a.wideString is null
				and not a.ukey_parent is null

	--select *
	--		from #results a
	--		join #results b on b.ukey = a.ukey + 1
	--			and a.keyName = b.keyName
	--			and a.ukey_parent = b.ukey_parent
	--		join (select ukey_parent, keyName, min(ukey) as minUkey from #results group by ukey_parent, keyName) x on a.ukey_parent = x.ukey_parent
	--			and a.keyName = x.keyName
	--			and a.ukey = x.minUkey
	--		where not a.wideString is null
	--			and a.ukey_parent = 3

		delete b
			from #results a
			join #results b on a.keyName = b.keyName
				and a.ukey_parent = b.ukey_parent
			join (select ukey_parent, keyName, min(ukey) as minUkey from #results group by ukey_parent, keyName) x on a.ukey_parent = x.ukey_parent
				and a.keyName = x.keyName
				and a.ukey = x.minUkey
			join (select ukey_parent, keyName, min(ukey) as minUkey from #results where not wideString like keyName + '%' group by ukey_parent, keyName) y on a.ukey_parent = y.ukey_parent
				and a.keyName = y.keyName
				and b.ukey = y.minUkey
			where not a.wideString is null
				and not a.ukey_parent is null

		set @nRowCount = @@ROWCOUNT
	end

	--select * from #results order by ukey

	update #results set objectName = keyValue where keyName = 'CanonicalName'

	update a
		set objectName = b.objectName
		from #results a
		join #results b on a.ukey_parent = b.ukey_parent
			and b.objectName is not null
		where a.objectName  is null

--	select * from #results where objectName like '%getzler%' order by ukey
--	select * from #results where objectName like '%mcswain%' order by ukey
--	select * from #results where objectName like '%sqldb35%' order by ukey

	-- ************************************************************************************************************************************************************************
	-- ************************************************************************************************************************************************************************
	-- ************************************************************************************************************************************************************************
	-- ************************************************************************************************************************************************************************

	-- Update the AUDIT tables with the results of our scans

	update auditData_activeDirectory
		set isCurrent = 0
		-- select *
		from auditData_activeDirectory a
		left outer join #results b on a.keyName = b.keyName
			and a.keyValue = b.keyValue
			and a.objectName = b.objectName
		where a.servername = '10.10.10.201'
			and a.isCurrent = 1
			and b.ukey is null

	update auditData_activeDirectory
		set ymd_lastSeen = getDate()
		from auditData_activeDirectory a
		join #results b on a.keyName = b.keyName
			and a.keyValue = b.keyValue
			and a.objectName = b.objectName
		where a.servername = '10.10.10.201'
			and a.isCurrent = 1

	-- get rid of any doubles in the existing data
	delete auditData_activeDirectory
		-- select *
		from auditData_activeDirectory a
		join (select serverName, objectname, keyname, max(ukey) as maxUkey from auditData_activeDirectory where isCurrent = 1 group by objectname, keyname, servername having count(*) > 1) b on a.objectName = b.objectName
			and a.keyName = b.keyName
			and a.serverName = b.serverName
		where a.ukey <> b.maxUkey
			and a.isCurrent = 1

	delete #results
		-- select *
		from #results a
		join (select objectname, keyname, max(ukey) as maxUkey from #results group by objectname, keyname having count(*) > 1) b on a.objectName = b.objectName
			and a.keyName = b.keyName
		where a.ukey <> b.maxUkey

--delete from auditData_activeDirectory where ukey = 49785
--select * from auditData_activeDirectory where objectName = 'corp.example.com/DisabledUsers/Example User' and isCurrent = 1 order by keyname
--select * from #results where objectName like '%corp.example.com/DisabledUsers/Example User%' order by ukey
--select * from #results where widestring like '%mcswain%'

	--insert into notification..notificationLog_stage (ymd, subject, message, severity, serverName)
	--select getDate(),
	--	left('AD Change: ' + a.objectName + ' : ' + a.keyName + ' : ' + a.keyValue, 300),
	--	left('AD Change: ' + a.objectName + ' : ' + a.keyName + ' : ' + a.keyValue + '<br>' +
	--		isnull(b.keyName, 'N/A') + ' : ' + isnull(b.keyValue, 'N/A'), 8000),
	--	2,
	--	'10.10.10.201'
	--	-- select *
	--	from #results a
	--	left outer join auditData_activeDirectory b on b.serverName = '10.10.10.201'
	--		and a.keyName = b.keyName
	--		and a.objectName = b.objectName
	--		and b.isCurrent = 1

	--	where (b.ukey is null or a.keyValue <> b.keyValue)
	--		and a.keyName is not null
	--		and a.keyValue is not null
	--		and a.objectName is not null
	--		and a.keyName in ('AccountLockoutTime', 'LockedOut', 'PasswordExpired',
	--			'DistinguishedName', 'OperatingSystem', 'OperatingSystemServicePack', 'OperatingSystemHotfix', 'OperatingSystemVersion', 'ObjectCategory', 'PrimaryGroup') -- 'PasswordLastSet', 'Enabled', 'CanonicalName', 'isDeleted', 'MemberOf', 'IPv4Address',

	insert into auditData_activeDirectory (serverName, keyName, keyValue, objectName, isCurrent, ymd_lastSeen)
	select '10.10.10.201', a.keyName, a.keyValue, a.objectName, 1, getDate()
		from #results a
		left outer join auditData_activeDirectory b on b.serverName = '10.10.10.201'
			and a.keyName = b.keyName
			and a.keyValue = b.keyValue
			and a.objectName = b.objectName
			and b.isCurrent = 1

		where b.ukey is null
			and a.keyName is not null
			and a.keyValue is not null
			and a.objectName is not null
--			and a.keyName in ('AccountLockoutTime', 'isDeleted', 'LockedOut', 'MemberOf', 'PasswordExpired', 'PasswordLastSet', 'Enabled')
	--		and a.keyName not in ('lastLogon', 'logonCount', 'badPasswordTime', 'LastBadPasswordAttempt', 'LastLogonDate', 'lastLogonTimestamp', 'Modified', 'whenChanged', 'modifyTimeStamp', 'uSNChanged', 'pwdLastSet', 'BadLogonCount', 'badPwdCount', 'userAccountControl')
		order by objectName, keyName, keyValue

	drop table #results

end
GO
