/****** Object:  StoredProcedure [dbo].[pr_securityauditData_temp]    Script Date: 05/07/2009 10:30:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_securityauditData_temp]
		as
		begin
			insert into #databases
			select 'ttssvr' as serverName, [name]
				from openquery([ttssvr], '
					select [name]
						from master.dbo.sysdatabases
						where (status & 32) <> 32 -- loading
								and (status & 64) <> 64 -- prerecovery
								and (status & 128) <> 128 -- recovery
								and (status & 512) <> 512 -- offline
								and (status & 4096) <> 4096 -- single user
					')


			declare @cThisDatabase varchar(200)
			declare @cSQLString nvarchar(4000)
			declare @cServerName varchar(100)
			set @cThisDatabase = ''
			set @cServerName = 'ttssvr'

			while exists (select top 1 databaseName from #databases where serverName = 'ttssvr' and databaseName > @cThisDatabase order by databaseName)
			begin
				set @cThisDatabase = (
					select top 1 databaseName
						from #databases
						where serverName = 'ttssvr' and databaseName > @cThisDatabase
						order by databaseName
					)

				print @cThisDatabase

				set @cSQLString = '
					create procedure pr_securityauditData_temp2
					as
					begin
						insert into auditData_sysusers (ukey_server, databaseName, ukey_auditRun, uid, status, name, sid, roles, createdate,
							updatedate, altuid, password, gid, isntgroup, isntuser)
						select 2 as ukey_server, ' + char(39) + @cThisDatabase + char(39) + ' as databaseName,
							751 as ukey_auditRun,
							uid, status, name, sid, roles, createdate, updatedate, altuid, password, gid, isntgroup, isntuser
							from [ttssvr].[' + @cThisDatabase + '].dbo.sysusers
					end'

				exec sp_executeSQL @cSQLString
				exec pr_securityauditData_temp2
				drop procedure [dbo].[pr_securityauditData_temp2]

				set @cSQLString = '
					create procedure pr_securityauditData_temp2
					as
					begin
						insert into auditData_syspermissions (ukey_server, databaseName, ukey_auditRun, id, grantee, grantor, actadd, actmod, seladd,
							selmod, updadd, updmod, refadd, refmod)
						select 2 as ukey_server, ' + char(39) + @cThisDatabase + char(39) + ' as databaseName,
							751 as ukey_auditRun,
							id, grantee, grantor, actadd, actmod, seladd, selmod, updadd, updmod, refadd, refmod
							from [ttssvr].[' + @cThisDatabase + '].dbo.syspermissions
					end'

				exec sp_executeSQL @cSQLString
				exec pr_securityauditData_temp2
				drop procedure [dbo].[pr_securityauditData_temp2]

				set @cSQLString = '
					create procedure pr_securityauditData_temp2
					as
					begin
						insert into auditData_sysmembers (ukey_server, databaseName, ukey_auditRun, memberuid, groupuid)
						select 2 as ukey_server, ' + char(39) + @cThisDatabase + char(39) + ' as databaseName,
							751 as ukey_auditRun,
							memberuid, groupuid
							from [ttssvr].[' + @cThisDatabase + '].dbo.sysmembers
					end'

				exec sp_executeSQL @cSQLString
				exec pr_securityauditData_temp2
				drop procedure [dbo].[pr_securityauditData_temp2]

				set @cSQLString = '
					create procedure pr_securityauditData_temp2
					as
					begin
						insert into auditData_sysprotects (ukey_server, databaseName, ukey_auditRun, [id], [uid], [action], [protecttype], [columns], [grantor])
						select 2 as ukey_server, ' + char(39) + @cThisDatabase + char(39) + ' as databaseName,
							751 as ukey_auditRun,
							[id], [uid], [action], [protecttype], [columns], [grantor]
							from [ttssvr].[' + @cThisDatabase + '].dbo.sysprotects
					end'

				exec sp_executeSQL @cSQLString
				exec pr_securityauditData_temp2
				drop procedure [dbo].[pr_securityauditData_temp2]

			end
		end
GO
