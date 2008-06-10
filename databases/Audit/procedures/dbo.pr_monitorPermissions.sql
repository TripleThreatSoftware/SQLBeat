-- select * from auditRuns

ALTER   procedure [dbo].[pr_monitorPermissions]
as
begin
	declare @cServerName varchar(200)
	declare @cDatabaseName varchar(200)
	declare @cSQLString nvarchar(4000)
	declare @cMessage varchar(8000)
	declare @cGroupName varchar(100)
	declare @nUkeyServer int
	declare @nUkeyAuditRun int
	declare @nUkeyLastAuditRun int
	declare @bChangesFound bit
	declare @cThisSubject varchar(500)
	declare @cDomainName varchar(100)

	set @cDomainName = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'Domain')
	set @nUkeyAuditRun = null
	set @nUkeyLastAuditRun = (select max(ukey) from auditRuns)

--	set @nUkeyAuditRun = (select max(ukey) from auditRuns)
--	set @nUkeyLastAuditRun = (select max(ukey) from auditRuns where ukey < @nUkeyAuditRun) --22

	set nocount on

	--********************************************************************************************************************************************
	--********************************************************************************************************************************************
	create table #databases (serverName varchar(200), databaseName varchar(200))
	create table #userPermissions (serverName varchar(200), databaseName varchar(200),
		userName varchar(100), isRole varchar(1), isNTGroup varchar(1), isNTUser varchar(1), canSelect varchar(1),
		canInsert varchar(1), canDelete varchar(1), canUpdate varchar(1), canChangeStructure varchar(1),
		canExecute varchar(1), isDBO varchar(1))
	create table #results (ukey int identity, outputString varchar(100))

	if not exists (select top 1 [name] from sysobjects where xtype = 'U' and [name] = 'auditRuns')
	begin
		create table auditRuns (ukey int identity, ymd dateTime default getDate())
	end

	if not exists (select top 1 [name] from sysobjects where xtype = 'U' and [name] = 'auditData_ntUsers')
	begin
		create table auditData_ntUsers (ukey int identity, ukey_auditRun int, groupname varchar(100), userName varchar(100))
	end

	if not exists (select top 1 [name] from sysobjects where xtype = 'U' and [name] = 'auditData_sysusers')
	begin
		CREATE TABLE [auditData_sysusers] (ukey int identity, ukey_server int, databaseName varchar(200), ukey_auditRun int,
			[uid] [smallint], [status] [smallint], [name] [sysname], [sid] [varbinary] (85), [roles] [varbinary] (2048),
			[createdate] [datetime], [updatedate] [datetime], [altuid] [smallint], [password] [varbinary] (256), gid smallint,
			isNTGroup bit, isNTUser bit)
	end

	if not exists (select top 1 [name] from sysobjects where xtype = 'U' and [name] = 'auditData_syspermissions')
	begin
		CREATE TABLE [auditData_syspermissions] (ukey int identity, ukey_server int, databaseName varchar(200), ukey_auditRun int,
			[id] [int], [grantee] [smallint], [grantor] [smallint], [actadd] [smallint], [actmod] [smallint],
			[seladd] [varbinary] (4000), [selmod] [varbinary] (4000), [updadd] [varbinary] (4000), [updmod] [varbinary] (4000),
			[refadd] [varbinary] (4000), [refmod] [varbinary] (4000))
	end

	if not exists (select top 1 [name] from sysobjects where xtype = 'U' and [name] = 'auditData_sysmembers')
	begin
		CREATE TABLE [auditData_sysmembers] (ukey int identity, ukey_server int, databaseName varchar(200), ukey_auditRun int,
			[memberuid] [smallint], [groupuid] [smallint])
	end

	if not exists (select top 1 [name] from sysobjects where xtype = 'U' and [name] = 'auditData_sysprotects')
	begin
		CREATE TABLE [auditData_sysprotects] (ukey int identity, ukey_server int, databaseName varchar(200), ukey_auditRun int,
			[id] [int], [uid] [smallint], [action] [tinyint], [protecttype] [tinyint], [columns] [varbinary] (4000), [grantor] [smallint])
	end

	--********************************************************************************************************************************************
	-- parse each server, if we're not just comparing past runs
	--********************************************************************************************************************************************

	print 'Last run was ' + convert(varchar(20), isnull(@nUkeyAuditRun, 0))

	if isnull(@nUkeyAuditRun, 0) = 0
	begin
		insert into auditRuns (ymd) values (getDate())
		set @nUkeyAuditRun = (select scope_identity())

		set @cServerName = ''

		while exists (select * from notification.dbo.dm_servers where serverName > @cServerName and isEnabled = 1 and securityCheck = 1)
		begin
			select top 1
				@cServerName = serverName,
				@nUkeyServer = ukey
				from notification.dbo.dm_servers
				where serverName > @cServerName
					and isEnabled = 1
					and securityCheck = 1
				order by servername

			print 'Processing ' + @cServerName

			set @cDatabaseName = ''

			if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_securityauditData_temp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
				drop procedure [dbo].[pr_securityauditData_temp]
			if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_securityauditData_temp2]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
				drop procedure [dbo].[pr_securityauditData_temp2]

			set @cSQLString = '
		create procedure pr_securityauditData_temp
		as
		begin
			insert into #databases
			select ''' + @cServerName + ''' as serverName, [name]
				from openquery([' + @cServerName + '], ''
					select [name]
						from master.dbo.sysdatabases
						where (status & 32) <> 32 -- loading
								and (status & 64) <> 64 -- prerecovery
								and (status & 128) <> 128 -- recovery
								and (status & 512) <> 512 -- offline
								and (status & 4096) <> 4096 -- single user
					'')


			declare @cThisDatabase varchar(200)
			declare @cSQLString nvarchar(4000)
			declare @cServerName varchar(100)
			set @cThisDatabase = ''''
			set @cServerName = ''' + @cServerName + '''

			while exists (select top 1 databaseName from #databases where serverName = ''' + @cServerName + ''' and databaseName > @cThisDatabase order by databaseName)
			begin
				set @cThisDatabase = (
					select top 1 databaseName
						from #databases
						where serverName = ''' + @cServerName + ''' and databaseName > @cThisDatabase
						order by databaseName
					)

				print @cThisDatabase

				set @cSQLString = ''
					create procedure pr_securityauditData_temp2
					as
					begin
						insert into auditData_sysusers (ukey_server, databaseName, ukey_auditRun, uid, status, name, sid, roles, createdate,
							updatedate, altuid, password, gid, isntgroup, isntuser)
						select ' + convert(varchar(20), @nUkeyServer) + ' as ukey_server, '' + char(39) + @cThisDatabase + char(39) + '' as databaseName,
							' + convert(varchar(20), @nUkeyAuditRun) + ' as ukey_auditRun,
							uid, status, name, sid, roles, createdate, updatedate, altuid, password, gid, isntgroup, isntuser
							from [' + @cServerName + '].['' + @cThisDatabase + ''].dbo.sysusers
					end''

				exec sp_executeSQL @cSQLString
				exec pr_securityauditData_temp2
				drop procedure [dbo].[pr_securityauditData_temp2]

				set @cSQLString = ''
					create procedure pr_securityauditData_temp2
					as
					begin
						insert into auditData_syspermissions (ukey_server, databaseName, ukey_auditRun, id, grantee, grantor, actadd, actmod, seladd,
							selmod, updadd, updmod, refadd, refmod)
						select ' + convert(varchar(20), @nUkeyServer) + ' as ukey_server, '' + char(39) + @cThisDatabase + char(39) + '' as databaseName,
							' + convert(varchar(20), @nUkeyAuditRun) + ' as ukey_auditRun,
							id, grantee, grantor, actadd, actmod, seladd, selmod, updadd, updmod, refadd, refmod
							from [' + @cServerName + '].['' + @cThisDatabase + ''].dbo.syspermissions
					end''

				exec sp_executeSQL @cSQLString
				exec pr_securityauditData_temp2
				drop procedure [dbo].[pr_securityauditData_temp2]

				set @cSQLString = ''
					create procedure pr_securityauditData_temp2
					as
					begin
						insert into auditData_sysmembers (ukey_server, databaseName, ukey_auditRun, memberuid, groupuid)
						select ' + convert(varchar(20), @nUkeyServer) + ' as ukey_server, '' + char(39) + @cThisDatabase + char(39) + '' as databaseName,
							' + convert(varchar(20), @nUkeyAuditRun) + ' as ukey_auditRun,
							memberuid, groupuid
							from [' + @cServerName + '].['' + @cThisDatabase + ''].dbo.sysmembers
					end''

				exec sp_executeSQL @cSQLString
				exec pr_securityauditData_temp2
				drop procedure [dbo].[pr_securityauditData_temp2]

				set @cSQLString = ''
					create procedure pr_securityauditData_temp2
					as
					begin
						insert into auditData_sysprotects (ukey_server, databaseName, ukey_auditRun, [id], [uid], [action], [protecttype], [columns], [grantor])
						select ' + convert(varchar(20), @nUkeyServer) + ' as ukey_server, '' + char(39) + @cThisDatabase + char(39) + '' as databaseName,
							' + convert(varchar(20), @nUkeyAuditRun) + ' as ukey_auditRun,
							[id], [uid], [action], [protecttype], [columns], [grantor]
							from [' + @cServerName + '].['' + @cThisDatabase + ''].dbo.sysprotects
					end''

				exec sp_executeSQL @cSQLString
				exec pr_securityauditData_temp2
				drop procedure [dbo].[pr_securityauditData_temp2]

			end
		end'
			print @cSQLString
			exec sp_executeSQL @cSQLString

			exec pr_securityauditData_temp

			update notification.dbo.dm_servers
				set lastSecurityCheck = getDate()
				where serverName = @cServerName
		end

		--********************************************************************************************************************************************
		-- identify NT groups
		--********************************************************************************************************************************************

		set @cGroupName = ''

		while exists (
			select distinct [name]
				from auditData_sysusers
				where isNTGroup = 1
					and [name] > @cGroupName
			)
		begin
			select top 1 @cGroupName = [name]
				from auditData_sysusers
				where isNTGroup = 1
					and [name] > @cGroupName
				order by [name]

			declare @cCommand varchar(500)
			declare @bContinue bit

			set @cCommand = 'net group "' + @cGroupname + '" /domain'

		--	print @cCommand

			insert into #results (outputString)
			exec master..xp_cmdshell @cCommand

			delete from #results where ukey <= 8
			delete from #results where ukey >= (select max(ukey) - 2 from #results)

			set @bContinue = 1

			while @bContinue = 1
			begin
				insert into auditData_ntUsers (ukey_auditRun, groupName, username)
				select @nUkeyAuditRun, @cGroupname,
					rtrim(left(outputString, case when charindex(' ', outputString) > 0 then charindex(' ', outputString) else 99 end))
					from #results
					where len(outputString) > 0

				if @@rowcount = 0
					set @bContinue = 0

				update #results
					set outputString = ''
					where charindex(' ', outputString) = 0

				update #results
					set outputString = rtrim(ltrim(substring(outputString, charindex(' ', outputString), 99)))
					where charindex(' ', outputString) > 0
			end

			truncate table #results
		end
	end

	if isnull(@nUkeyLastAuditRun, 0) <> 0
	begin
		--************************************************************************************************************************
		-- results of last audit
		--************************************************************************************************************************
		select distinct d.ukey_server, d.databaseName, d.memberUID as UID, e.action, f.name
			into #lastRunGroupPermissions
			-- groups to which this user belongs
			from auditData_sysmembers d
			-- group name
			join auditData_sysusers f on d.ukey_server = f.ukey_server
				and f.ukey_auditRun = @nUkeyLastAuditRun
				and d.databaseName = f.databaseName
				and (f.uid = d.groupUID or f.[name] = 'public')
			-- permissions from group membership
			join auditData_sysprotects e on d.ukey_server = e.ukey_server
				and e.ukey_auditRun = @nUkeyLastAuditRun
				and d.databaseName = e.databaseName
				and f.uid = e.uid
				and e.protectType in (204, 205)
			where d.ukey_auditRun = @nUkeyLastAuditRun

		create clustered index ix_tmp_lastRunPermissions on #lastRunGroupPermissions (ukey_server, databaseName, uid) with fillfactor = 100

		select
			s.serverName,
			b.databaseName,
			b.[name] as userName,
			case when b.uid = b.gid then 'X' else '' end as isRole,
			b.isNTGroup,
			b.isNTUser,
			max(case when c.action = 193 or isnull(d.action, 0) = 193 or isnull(d.[name], '') = 'db_dataReader' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canSelect,
			max(case when c.action = 195 or isnull(d.action, 0) = 195 or isnull(d.[name], '') = 'db_dataWriter' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canInsert,
			max(case when c.action = 196 or isnull(d.action, 0) = 196 or isnull(d.[name], '') = 'db_dataWriter' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canDelete,
			max(case when c.action = 197 or isnull(d.action, 0) = 197 or isnull(d.[name], '') = 'db_dataWriter' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canUpdate,
			max(case when c.action = 197 or isnull(d.action, 0) = 197 or isnull(d.[name], '') = 'db_ddladmin' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canChangeStructure,
			max(case when c.action = 224 or isnull(d.action, 0) = 224 or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canExecute,
			max(case when isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as isDBO

			into #userPermissions_lastAudit

			from notification.dbo.dm_servers s
			join auditData_sysusers b on s.ukey = b.ukey_server
				and b.ukey_auditRun = @nUkeyLastAuditRun
				and b.[name] not in ('db_accessadmin', 'db_backupoperator', 'db_datareader', 'db_datawriter', 'db_ddladmin',
					'db_denydatareader', 'db_denydatawriter', 'db_owner', 'db_securityadmin', 'dbo')
				and b.databaseName not in ('pubs', 'tempdb', 'master', 'model', 'msdb')
			-- user's specific rights
			left outer join auditData_sysprotects c on s.ukey = c.ukey_server
				and c.ukey_auditRun = @nUkeyLastAuditRun
				and b.databaseName = c.databaseName
				and b.uid = c.uid
				and c.protectType in (204, 205)
			left outer join #lastRunGroupPermissions d on s.ukey = d.ukey_server
				and b.databaseName = d.databaseName
				and b.uid = d.uid

			where s.isEnabled = 1
				and s.securityCheck = 1

			group by s.serverName, b.databaseName, b.[name], case when b.uid = b.gid then 'X' else '' end, b.isNTGroup, b.isNTUser

		--********************************************************************************************************************************************
		-- look at changes to the NT groups
		--********************************************************************************************************************************************

		set @cMessage = ''

		select @cMessage = @cMessage + 'User "' + isnull(a.userName, 'UNKNOWN') + '" has been added to NT Group "' + a.groupName + '".' + char(13)
			from auditData_ntUsers a
			left outer join auditData_ntUsers b on a.groupName = b.groupName
				and a.userName = b.userName
				and b.ukey_auditRun = @nUkeyLastAuditRun
			where a.ukey_auditRun = @nUkeyAuditRun
				and b.ukey is null

		select @cMessage = @cMessage + 'User "' + isnull(a.userName, 'UNKNOWN') + '" has been removed from NT Group "' + a.groupName + '".' + char(13)
			from auditData_ntUsers a
			left outer join auditData_ntUsers b on a.groupName = b.groupName
				and a.userName = b.userName
				and b.ukey_auditRun = @nUkeyAuditRun
			where a.ukey_auditRun = @nUkeyLastAuditRun
				and b.ukey is null

		set @cThisSubject = 'SAA : NT Group membership changes'

		if @cMessage <> ''
		begin
			print @cThisSubject
			print @cMessage

			exec notification.dbo.pr_sendMessage '', 'DBA', @cThisSubject, @cMessage
		end

		--********************************************************************************************************************************************
		-- compare each server one at a time
		--********************************************************************************************************************************************

		select distinct d.ukey_server, d.databaseName, d.memberUID as UID, e.action, f.name
			into #thisRunGroupPermissions
			-- groups to which this user belongs
			from auditData_sysmembers d
			-- group name
			join auditData_sysusers f on d.ukey_server = f.ukey_server
				and f.ukey_auditRun = @nUkeyAuditRun
				and d.databaseName = f.databaseName
				and (f.uid = d.groupUID or f.[name] = 'public')
			-- permissions from group membership
			join auditData_sysprotects e on d.ukey_server = e.ukey_server
				and e.ukey_auditRun = @nUkeyAuditRun
				and d.databaseName = e.databaseName
				and f.uid = e.uid
				and e.protectType in (204, 205)
			where d.ukey_auditRun = @nUkeyAuditRun

		create clustered index ix_tmp_thisRunPermissions on #thisRunGroupPermissions (ukey_server, databaseName, uid) with fillfactor = 100

		set @cServerName = ''

		while exists (select * from notification.dbo.dm_servers where serverName > @cServerName and isEnabled = 1 and securityCheck = 1)
		begin
			select top 1 @cServerName = serverName
				from notification.dbo.dm_servers
				where serverName > @cServerName
					and isEnabled = 1
					and securityCheck = 1
				order by servername

			truncate table #userPermissions
			set @bChangesFound = 0

			-- summary of permissions for this pass
			insert into #userPermissions (serverName, databaseName, userName, isRole, isNTGroup, isNTUser, canSelect, canInsert, canDelete,
				canUpdate, canChangeStructure, canExecute, isDBO)
			select a.serverName, b.databaseName,
				b.[name] as userName,
				case when b.uid = b.gid then 'X' else '' end as isRole,
				b.isNTGroup,
				b.isNTUser,
				max(case when c.action = 193 or isnull(d.action, 0) = 193 or isnull(d.[name], '') = 'db_dataReader' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canSelect,
				max(case when c.action = 195 or isnull(d.action, 0) = 195 or isnull(d.[name], '') = 'db_dataWriter' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canInsert,
				max(case when c.action = 196 or isnull(d.action, 0) = 196 or isnull(d.[name], '') = 'db_dataWriter' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canDelete,
				max(case when c.action = 197 or isnull(d.action, 0) = 197 or isnull(d.[name], '') = 'db_dataWriter' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canUpdate,
				max(case when c.action = 197 or isnull(d.action, 0) = 197 or isnull(d.[name], '') = 'db_ddladmin' or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canChangeStructure,
				max(case when c.action = 224 or isnull(d.action, 0) = 224 or isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as canExecute,
				max(case when isnull(d.[name], '') = 'db_owner' then 'X' else '' end) as isDBO

				from notification.dbo.dm_servers a
				join auditData_sysusers b on a.ukey = b.ukey_server
					and b.ukey_auditRun = @nUkeyAuditRun
					and b.[name] not in ('db_accessadmin', 'db_backupoperator', 'db_datareader', 'db_datawriter', 'db_ddladmin',
						'db_denydatareader', 'db_denydatawriter', 'db_owner', 'db_securityadmin', 'dbo')
					and b.databaseName not in ('pubs', 'tempdb', 'master', 'model', 'msdb')
				-- user's specific rights
				left outer join auditData_sysprotects c on a.ukey = c.ukey_server
					and c.ukey_auditRun = @nUkeyAuditRun
					and b.databaseName = c.databaseName
					and b.uid = c.uid
					and c.protectType in (204, 205)
				-- groups to which this user belongs
				left outer join #thisRunGroupPermissions d on a.ukey = d.ukey_server
					and b.databaseName = d.databaseName
					and b.uid = d.uid

				where a.serverName = @cServerName

				group by a.serverName, b.databaseName, b.[name], case when b.uid = b.gid then 'X' else '' end, b.isNTGroup, b.isNTUser

			print convert(varchar(20), @@rowcount) + ' records for ' + @cServerName + ', run ' + convert(varchar(20), @nUkeyAuditRun)

			set @cMessage = '
	(permissions changes since the last audit)
																						  BEFORE                AFTER
																				   --------------------- ---------------------
																			 N    |                     |                     |
																			 T  N |                     |                     |
																				T | S  I  D  U          | S  I  D  U          |
																			 G    | e  n  e  p  A       | e  n  e  p  A       |
																		  R  r  U | l  s  l  d  l  E    | l  s  l  d  l  E    |
																		  o  o  s | e  e  e  a  t  x  D | e  e  e  a  t  x  D |
																		  l  u  e | c  r  t  t  e  e  B | c  r  t  t  e  e  B |
	NT Group       User           Server              Database            e  p  r | t  t  e  e  r  c  O | t  t  e  e  r  c  O |
	============== ============== =================== =================== ======== ===================== =====================
	'

			-- new rights
			select @cMessage = @cMessage +
				left(a.groupName + space(15), 15) +
					left(a.userName + space(15), 15) +
					left(a.serverName + space(20), 20) +
					left(a.databaseName + space(20), 20) +

					left(a.isRole + space(3), 3) +
					left(case when a.isNTGroup = 1 then 'X' else '' end + space(3), 3) +
					left(case when a.isNTUser = 1 then 'X' else '' end + space(3), 3) +

					space(1) +

					left(isnull(b.canSelect, '-') + space(3), 3) +
					left(isnull(b.canInsert, '-') + space(3), 3) +
					left(isnull(b.canDelete, '-') + space(3), 3) +
					left(isnull(b.canUpdate, '-') + space(3), 3) +
					left(isnull(b.canChangeStructure, '-') + space(3), 3) +
					left(isnull(b.canExecute, '-') + space(3), 3) +
					left(isnull(b.isDBO, '-') + space(3), 3) +

					space(1) +

					left(a.canSelect + space(3), 3) +
					left(a.canInsert + space(3), 3) +
					left(a.canDelete + space(3), 3) +
					left(a.canUpdate + space(3), 3) +
					left(a.canChangeStructure + space(3), 3) +
					left(a.canExecute + space(3), 3) +
					left(a.isDBO + space(3), 3) +

					char(13)

				from (
					select isnull(a.groupName, '') as groupName, isnull(a.userName, b.userName) as userName, b.serverName, b.databaseName,
						b.isRole, b.isNTGroup, b.isNTUser, b.canSelect, b.canInsert, b.canDelete, b.canUpdate, b.canChangeStructure, b.canExecute, b.isDBO
						from #userPermissions b
						left outer join auditData_ntUsers a on (
								replace(a.userName, @cDomainName + '\', '') = replace(b.userName, @cDomainName + '\', '')
								or (b.isNTGroup = 1 and replace(a.groupName, @cDomainName + '\', '') = replace(b.userName, @cDomainName + '\', ''))
							)
							and a.ukey_auditRun = @nUkeyAuditRun
						where b.servername = @cServerName
					) a
				left outer join (
					select isnull(a.groupName, '') as groupName, isnull(a.userName, b.userName) as userName, b.serverName, b.databaseName,
						b.isRole, b.isNTGroup, b.isNTUser, b.canSelect, b.canInsert, b.canDelete, b.canUpdate, b.canChangeStructure, b.canExecute, b.isDBO
						from #userPermissions_lastAudit b
						left outer join auditData_ntUsers a on (
								replace(a.userName, @cDomainName + '\', '') = replace(b.userName, @cDomainName + '\', '')
								or (b.isNTGroup = 1 and replace(a.groupName, @cDomainName + '\', '') = replace(b.userName, @cDomainName + '\', ''))
							)
							and a.ukey_auditRun = @nUkeyLastAuditRun
						where b.servername = @cServerName
					) b on a.groupName = b.groupName
						and a.userName = b.username
						and a.serverName = b.serverName
						and a.databaseName = b.databaseName
						and a.isRole = b.isRole
						and a.isNTGroup = b.isNTGroup
						and a.isNTUser = b.isNTUser
						and a.canSelect = b.canSelect
						and a.canInsert = b.canInsert
						and a.canDelete = b.canDelete
						and a.canUpdate = b.canUpdate
						and a.canChangeStructure = b.canChangeStructure
						and a.canExecute = b.canExecute
						and a.isDBO = b.isDBO

				where b.userName is null

				order by a.serverName, a.databaseName, a.userName, a.groupName

			if @@rowcount > 0
				set @bChangesFound = 1

			-- rights taken away
			select @cMessage = @cMessage +
				left(a.groupName + space(15), 15) +
					left(a.userName + space(15), 15) +
					left(a.serverName + space(20), 20) +
					left(a.databaseName + space(20), 20) +

					left(a.isRole + space(3), 3) +
					left(case when a.isNTGroup = 1 then 'X' else '' end + space(3), 3) +
					left(case when a.isNTUser = 1 then 'X' else '' end + space(3), 3) +

					space(1) +

					left(a.canSelect + space(3), 3) +
					left(a.canInsert + space(3), 3) +
					left(a.canDelete + space(3), 3) +
					left(a.canUpdate + space(3), 3) +
					left(a.canChangeStructure + space(3), 3) +
					left(a.canExecute + space(3), 3) +
					left(a.isDBO + space(3), 3) +

					space(1) +

					left(isnull(b.canSelect, '-') + space(3), 3) +
					left(isnull(b.canInsert, '-') + space(3), 3) +
					left(isnull(b.canDelete, '-') + space(3), 3) +
					left(isnull(b.canUpdate, '-') + space(3), 3) +
					left(isnull(b.canChangeStructure, '-') + space(3), 3) +
					left(isnull(b.canExecute, '-') + space(3), 3) +
					left(isnull(b.isDBO, '-') + space(3), 3) +

					char(13)
				from (
					select isnull(a.groupName, '') as groupName, isnull(a.userName, b.userName) as userName, b.serverName, b.databaseName,
						b.isRole, b.isNTGroup, b.isNTUser, b.canSelect, b.canInsert, b.canDelete, b.canUpdate, b.canChangeStructure, b.canExecute, b.isDBO
						from #userPermissions_lastAudit b
						left outer join auditData_ntUsers a on (
								replace(a.userName, @cDomainName + '\', '') = replace(b.userName, @cDomainName + '\', '')
								or (b.isNTGroup = 1 and replace(a.groupName, @cDomainName + '\', '') = replace(b.userName, @cDomainName + '\', ''))
							)
							and a.ukey_auditRun = @nUkeyLastAuditRun
						where b.servername = @cServerName
					) a
				left outer join (
					select isnull(a.groupName, '') as groupName, isnull(a.userName, b.userName) as userName, b.serverName, b.databaseName,
						b.isRole, b.isNTGroup, b.isNTUser, b.canSelect, b.canInsert, b.canDelete, b.canUpdate, b.canChangeStructure, b.canExecute, b.isDBO
						from #userPermissions b
						left outer join auditData_ntUsers a on (
								replace(a.userName, @cDomainName + '\', '') = replace(b.userName, @cDomainName + '\', '')
								or (b.isNTGroup = 1 and replace(a.groupName, @cDomainName + '\', '') = replace(b.userName, @cDomainName + '\', ''))
							)
							and a.ukey_auditRun = @nUkeyAuditRun
						where b.servername = @cServerName
					) b on a.groupName = b.groupName
						and a.userName = b.username
						and a.serverName = b.serverName
						and a.databaseName = b.databaseName
						and a.isRole = b.isRole
						and a.isNTGroup = b.isNTGroup
						and a.isNTUser = b.isNTUser
						and a.canSelect = b.canSelect
						and a.canInsert = b.canInsert
						and a.canDelete = b.canDelete
						and a.canUpdate = b.canUpdate
						and a.canChangeStructure = b.canChangeStructure
						and a.canExecute = b.canExecute
						and a.isDBO = b.isDBO

				where b.userName is null

				order by a.serverName, a.databaseName, a.userName, a.groupName

			if @@rowcount > 0
				set @bChangesFound = 1

			set @cThisSubject = 'SAA : Permission change summary for ' + @cServerName

			if @bChangesFound = 1
			begin
				print @cThisSubject
				print @cMessage
				exec notification.dbo.pr_sendMessage '', 'DBA', @cThisSubject, @cMessage
			end
		end

		drop table #lastRunGroupPermissions
		drop table #thisRunGroupPermissions
		drop table #userPermissions_lastAudit
	end

	drop table #databases
	drop table #userPermissions
	drop table #results
end
GO
