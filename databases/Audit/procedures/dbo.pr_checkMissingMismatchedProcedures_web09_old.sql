/****** Object:  StoredProcedure [dbo].[pr_checkMissingMismatchedProcedures_web09_old]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_checkMissingMismatchedProcedures_web09_old]
as
begin

	select databasename, objectName, xtype,
		case
			when max(case when servername = 'web04' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web04' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web04],
		case
			when max(case when servername = 'web09' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web09' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web09],
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
			when max(case when servername = 'sqldm01.PRO' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldm01.PRO' then textchecksum else 0 end) <> max(case when servername = 'web25' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldm01.PRO]
		-------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- NOTE: WEB25 is now the "master" server for this process...
		-- This was done since WEB08 will be getting shipped off to the West Coast and will be out of commission for an extended period.
		-- JReed - 08.10.16
		-------------------------------------------------------------------------------------------------------------------------------------------------------------
		into #mismatchedprocedures
		from (
			select servername, databasename, objectName, xtype, sum(textchecksum) as textchecksum
				from auditData_objectText (nolock)
				where isCurrent = 1
					and servername in ('web04', 'web09', 'web17', 'web19', 'web20', 'web21', 'web22', 'web25', 'sqldb26', 'sqldm01.PRO')
					and databaseName in ('AppDb', 'AppDb_lite', 'AppDb_master')
					and right(objectName, 1) <> '2'
					and objectName not like '%old'
					and objectName not like 'pr_client%'
					and objectNAME <> 'pr_monitorSynchronizer'
					and xtype = 'P'
				group by databasename, objectName, xtype, servername
			) a
		group by databasename, objectName, xtype
		having count(distinct textchecksum) > 1
			or count(distinct servername) <> 7

		Select distinct databaseName, objectname, '' + case when web04 = 'MISMATCH' or web09 = 'MISMATCH' or web17 = 'MISMATCH' or web19 = 'MISMATCH'
															or web20 = 'MISMATCH' or web21 = 'MISMATCH' or web22 = 'MISMATCH' or sqldb26 = 'MISMATCH'
															or [sqldm01.PRO] = 'MISMATCH'
															then 'mismatched in: ' +
																	   case when web04 = 'MISMATCH' then 'Web04, ' else '' end +
																	   case when Web09 = 'MISMATCH' then 'Web09, ' else '' end +
																	   case when Web17 = 'MISMATCH' then 'Web17, ' else '' end +
																	   case when Web19 = 'MISMATCH' then 'Web19, ' else '' end +
																	   case when Web20 = 'MISMATCH' then 'Web20, ' else '' end +
																	   case when Web21 = 'MISMATCH' then 'Web21, ' else '' end +
																	   case when Web22 = 'MISMATCH' then 'Web22, ' else '' end +
																	   case when sqldb26 = 'MISMATCH' then 'sqldb26, ' else '' end +
																	   case when [sqldm01.PRO] = 'MISMATCH' then 'sqldm01.PRO, ' else '' end + ''
															else ''
														end +
														case when web04 = 'MISSING' or web09 = 'MISSING' or web17 = 'MISSING' or web19 = 'MISSING'
															or web20 = 'MISSING' or web21 = 'MISSING' or web22 = 'MISSING' or sqldb26 = 'MISSING'
															or [sqldm01.PRO] = 'MISSING'
															 then 'missing in: ' +
																	   case when web04 = 'MISSING' then 'Web04, ' else '' end +
																	   case when web09 = 'MISSING' then 'Web09, ' else '' end +
																	   case when Web17 = 'MISSING' then 'Web17, ' else '' end +
																	   case when Web19 = 'MISSING' then 'Web19, ' else '' end +
																	   case when Web20 = 'MISSING' then 'Web20, ' else '' end +
																	   case when Web21 = 'MISSING' then 'Web21, ' else '' end +
																	   case when Web22 = 'MISSING' then 'Web22, ' else '' end +
																	   case when sqldb26 = 'MISSING' then 'sqldb26, ' else '' end +
																	   case when [sqldm01.PRO] = 'MISSING' then 'sqldm01.PRO, ' else '' end + ''
															 else ''
														end as [message]
	into #mismatchedmessages
	from #mismatchedprocedures

	--insert into [sqldm01.PRO].Synchronize.dbo.errorMessages(ukey_website, errorSource, errorMessage)
	select
		0 as ukey_website,
		'Procedure missing or mismatched across SQL nodes ' + cast(cast(getDate() as date) as varchar(500)) + '.' as errorSource,
		'Procedure "' + objectName + '" in "' + databasename + '" is ' + left([message], len([message]) -1) as ErrorMessage
	from #mismatchedmessages
	where isnull(message, '') <> ''

	--drop table #mismatchedprocedures
	--drop table #mismatchedmessages
end
GO
