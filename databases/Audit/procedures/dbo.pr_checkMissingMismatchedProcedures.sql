USE [Audit]
GO
/****** Object:  StoredProcedure [dbo].[pr_checkMissingMismatchedProcedures]    Script Date: 6/19/2018 4:10:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_checkMissingMismatchedProcedures]
as
begin

	declare @servers table (servername varchar(100))

	insert into @servers (servername)
	select servername
		from notification..dm_servers
		where servername in ('web04', 'web06', 'web15', 'web17', 'web19', 'web20', 'web21', 'web22', 'web25', 'sqldb26', 'sqldb27', 'sqldm01.PRO', 'sqldb29', 'sqldb30', 'sqldb31', 'sqldb32', 'sqldm02')

	select databasename, objectName, xtype,
		case
			when max(case when servername = 'web04' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web04' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web04],
		case
			when max(case when servername = 'web06' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web06' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web06],
		case
			when max(case when servername = 'web15' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web15' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web15],
		case
			when max(case when servername = 'web17' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web17' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web17],
		case
			when max(case when servername = 'web19' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web19' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web19],
		case
			when max(case when servername = 'web20' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web20' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web20],
		case
			when max(case when servername = 'web21' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web21' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web21],
		case
			when max(case when servername = 'web22' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web22' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web22],
		case
			when max(case when servername = 'sqldb26' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb26' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb26],
		case
			when max(case when servername = 'sqldb27' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb27' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb27],
		case
			when max(case when servername = 'sqldm01.PRO' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldm01.PRO' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldm01.PRO],
	   case
			when max(case when servername = 'sqldb29' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb29' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb29],
	   case
			when max(case when servername = 'sqldb30' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb30' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb30],
	   case
			when max(case when servername = 'sqldb31' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb31' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb31],
	   case
			when max(case when servername = 'sqldb32' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb32' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb32],
	   case
			when max(case when servername = 'sqldm02' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldm02' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldm02]
		-------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- NOTE: WEB25 is now the "master" server for this process...
		-- This was done since WEB08 will be getting shipped off to the West Coast and will be out of commission for an extended period.
		-- JReed - 08.10.16
		-------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- select databasename, objectName, xtype
		into #mismatchedprocedures
		-- select databasename, objectName, xtype, count(distinct textchecksum), count(distinct servername)
		from (
			select servername, databasename, objectName, xtype, sum(textchecksum) as textchecksum
				from auditData_objectText (nolock)
				where isCurrent = 1
					and servername in (select servername from @servers)
					and databaseName in ('AppDb', 'AppDb_lite', 'AppDb_master')
					and right(objectName, 1) <> '2'
					and objectName not like '%old'
					and objectName not like 'pr_client%'
					and objectNAME <> 'pr_monitorSynchronizer'
					and xtype in ('P', 'FN', 'TF')
				group by databasename, objectName, xtype, servername
			) a
		group by databasename, objectName, xtype
		having count(distinct textchecksum) > 1
			or count(distinct servername) <> (select count(*) from @servers)

		Select distinct databaseName, objectname, '' + case when web04 = 'MISMATCH' or web06 = 'MISMATCH' or web15 = 'MISMATCH' or web17 = 'MISMATCH'
												or web19 = 'MISMATCH' or web20 = 'MISMATCH' or web21 = 'MISMATCH' or web22 = 'MISMATCH'
												or sqldb26 = 'MISMATCH' or sqldb27 = 'MISMATCH' or [sqldm01.PRO] = 'MISMATCH'
												or sqldb29 = 'MISMATCH' or sqldb30 = 'MISMATCH' or sqldb31 = 'MISMATCH' or sqldb32 = 'MISMATCH'
												or sqldm02 = 'MISMATCH'
															then 'mismatched in: ' +
																	   case when web04 = 'MISMATCH' then 'Web04, ' else '' end +
																	   case when Web06 = 'MISMATCH' then 'Web06, ' else '' end +
																	   case when Web15 = 'MISMATCH' then 'Web15, ' else '' end +
																	   case when Web17 = 'MISMATCH' then 'Web17, ' else '' end +
																	   case when Web19 = 'MISMATCH' then 'Web19, ' else '' end +
																	   case when Web20 = 'MISMATCH' then 'Web20, ' else '' end +
																	   case when Web21 = 'MISMATCH' then 'Web21, ' else '' end +
																	   case when Web22 = 'MISMATCH' then 'Web22, ' else '' end +
																	   case when sqldb26 = 'MISMATCH' then 'sqldb26, ' else '' end +
																	   case when sqldb27 = 'MISMATCH' then 'sqldb27, ' else '' end +
																	   case when [sqldm01.PRO] = 'MISMATCH' then 'sqldm01.PRO, ' else
																	   case when sqldb29 = 'MISMATCH' then 'sqldb29, ' else '' end +
																	   case when sqldb30 = 'MISMATCH' then 'sqldb30, ' else '' end +
																	   case when sqldb31 = 'MISMATCH' then 'sqldb31, ' else '' end +
																	   case when sqldb32 = 'MISMATCH' then 'sqldb32, ' else '' end +
																	   case when sqldm02 = 'MISMATCH' then 'sqldm02, ' else '' end +
																	   '' end + ''
															else ''
														end +
														case when web04 = 'MISSING' or web06 = 'MISSING' or web15 = 'MISSING' or web17 = 'MISSING'
															 or web19 = 'MISSING' or web20 = 'MISSING' or web21 = 'MISSING' or web22 = 'MISSING'
															 or sqldb26 = 'MISSING' or sqldb27 = 'MISSING' or [sqldm01.PRO] = 'MISSING'
															 or sqldb29 = 'MISSING' or sqldb30 = 'MISSING'or sqldb31 = 'MISSING' or sqldb32 = 'MISSING'
															 or sqldm02 = 'MISSING'
															 then 'missing in: ' +
																	   case when web04 = 'MISSING' then 'Web04, ' else '' end +
																	   case when web06 = 'MISSING' then 'Web06, ' else '' end +
																	   case when Web15 = 'MISSING' then 'Web15, ' else '' end +
																	   case when Web17 = 'MISSING' then 'Web17, ' else '' end +
																	   case when Web19 = 'MISSING' then 'Web19, ' else '' end +
																	   case when Web20 = 'MISSING' then 'Web20, ' else '' end +
																	   case when Web21 = 'MISSING' then 'Web21, ' else '' end +
																	   case when Web22 = 'MISSING' then 'Web22, ' else '' end +
																	   case when sqldb26 = 'MISSING' then 'sqldb26, ' else '' end +
																	   case when sqldb27 = 'MISSING' then 'sqldb27, ' else '' end +
																	   case when sqldb29 = 'MISSING' then 'sqldb29, ' else '' end +
																	   case when sqldb30 = 'MISSING' then 'sqldb30, ' else '' end +
																	   case when sqldb31 = 'MISSING' then 'sqldb31, ' else '' end +
																	   case when sqldb32 = 'MISSING' then 'sqldb32, ' else '' end +
																	   case when sqldm02 = 'MISSING' then 'sqldm02, ' else '' end +
																	   case when [sqldm01.PRO] = 'MISSING' then 'sqldm01.PRO, ' else '' end + ''
															 else ''
														end as [message]
	into #mismatchedmessages
	from #mismatchedprocedures

	insert into [sqldm01.PRO].Synchronize.dbo.errorMessages(ukey_website, errorSource, errorMessage)
	select
		0 as ukey_website,
		'Procedure missing or mismatched across SQL nodes ' + cast(cast(getDate() as date) as varchar(500)) + '.' as errorSource,
		'Procedure "' + objectName + '" in "' + databasename + '" is ' + left([message], len([message]) -1) as ErrorMessage
	from #mismatchedmessages
	where isnull(message, '') <> ''

	drop table #mismatchedprocedures
	drop table #mismatchedmessages
end
