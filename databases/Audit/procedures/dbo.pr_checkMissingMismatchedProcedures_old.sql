/****** Object:  StoredProcedure [dbo].[pr_checkMissingMismatchedProcedures_old]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_checkMissingMismatchedProcedures_old]
as
begin

	declare @servers table (servername varchar(100))

	insert into @servers (servername)
	select servername
		from notification..dm_servers
		where servername in ('web20', 'web22', 'web25', 'sqldb26', 'sqldb27', 'sqldb32'
			,'sqldb35', 'sqldb36'
		--	,'sqldb39'
			,'sqldb40', 'sqldb41', 'sqldb48', 'sqldb50', 'sqldb51'
			,'sqldm43', 'Atl-Sdm-044'
			,'Atl-Sql-090', 'Atl-Sql-091', 'Atl-Sql-092', 'Atl-Sql-093'
			,'Atl-Sql-096', 'Atl-Sql-097', 'Atl-Sql-098'
			,'Ams-Sql-100', 'Ams-Sql-101'
			,'Lhr-Sql-100', 'Lhr-Sql-101'
			,'Pdx-Sql-100', 'Pdx-Sql-101', 'Pdx-Sql-102', 'Pdx-Sql-103'
		)

	select databasename, objectName, xtype,
		case
			when max(case when servername = 'web20' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web20' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web20],
		case
			when max(case when servername = 'web22' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web22' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web22],
		case
			when max(case when servername = 'web25' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'web25' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Web25],
		case
			when max(case when servername = 'sqldb26' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb26' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb26],
		case
			when max(case when servername = 'sqldb27' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb27' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb27],
	   case
			when max(case when servername = 'sqldb32' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb32' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb32],
	   case
			when max(case when servername = 'sqldb35' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb35' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb35],
	   case
			when max(case when servername = 'sqldb36' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb36' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb36],
	  -- case
			--when max(case when servername = 'sqldb39' then textchecksum else 0 end) = 0 then 'MISSING'
			--when max(case when servername = 'sqldb39' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			--else ''
			--end as [sqldb39],
	   case
			when max(case when servername = 'sqldb40' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb40' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb40],
	   case
			when max(case when servername = 'sqldb41' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb41' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb41],
		case
			when max(case when servername = 'sqldb48' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb48' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb48],
		case
			when max(case when servername = 'sqldb50' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb50' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb50],
		case
			when max(case when servername = 'sqldb51' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldb51' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldb51],
	   case
			when max(case when servername = 'sqldm43' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'sqldm43' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [sqldm43],
		case
			when max(case when servername = 'Atl-Sdm-044' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Atl-Sdm-044' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Atl-Sdm-044],
		case
			when max(case when servername = 'Atl-Sql-090' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Atl-Sql-090' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Atl-Sql-090],
		case
			when max(case when servername = 'Atl-Sql-091' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Atl-Sql-091' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Atl-Sql-091],
		case
			when max(case when servername = 'Atl-Sql-092' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Atl-Sql-092' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Atl-Sql-092],
		case
			when max(case when servername = 'Atl-Sql-093' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Atl-Sql-093' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Atl-Sql-093],
		case
			when max(case when servername = 'Atl-Sql-096' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Atl-Sql-096' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Atl-Sql-096],
		case
			when max(case when servername = 'Atl-Sql-097' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Atl-Sql-097' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Atl-Sql-097],
		case
			when max(case when servername = 'Atl-Sql-098' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Atl-Sql-098' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Atl-Sql-098],
		case
			when max(case when servername = 'Ams-Sql-100' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Ams-Sql-100' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Ams-Sql-100],
		case
			when max(case when servername = 'Ams-Sql-101' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Ams-Sql-101' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Ams-Sql-101],
		case
			when max(case when servername = 'Lhr-Sql-100' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Lhr-Sql-100' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Lhr-Sql-100],
		case
			when max(case when servername = 'Lhr-Sql-101' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Lhr-Sql-101' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Lhr-Sql-101],
		case
			when max(case when servername = 'Pdx-Sql-100' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Pdx-Sql-100' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Pdx-Sql-100],
		case
			when max(case when servername = 'Pdx-Sql-101' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Pdx-Sql-101' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Pdx-Sql-101],
		case
			when max(case when servername = 'Pdx-Sql-102' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Pdx-Sql-102' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Pdx-Sql-102],
		case
			when max(case when servername = 'Pdx-Sql-103' then textchecksum else 0 end) = 0 then 'MISSING'
			when max(case when servername = 'Pdx-Sql-103' then textchecksum else 0 end) <> max(case when servername = 'sqldb39' then textchecksum else 0 end) then 'MISMATCH'
			else ''
			end as [Pdx-Sql-103]

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

	Select distinct
		databaseName,
		objectname,
		'' + case when
				web20 = 'MISMATCH' or web22 = 'MISMATCH' or web25 = 'MISMATCH' or sqldb26 = 'MISMATCH' or sqldb27 = 'MISMATCH'
					or sqldb32 = 'MISMATCH' or sqldb35 = 'MISMATCH' or sqldb36 = 'MISMATCH'
				--	or sqldb39 = 'MISMATCH'
					or sqldb40 = 'MISMATCH' or sqldb41 = 'MISMATCH' or sqldb48 = 'MISMATCH'
					or sqldb50 = 'MISMATCH' or sqldb51 = 'MISMATCH' or sqldm43 = 'MISMATCH' or Atl-Sdm-044 = 'MISMATCH'
					or Atl-Sql-090 = 'MISMATCH' or Atl-Sql-091 = 'MISMATCH' or Atl-Sql-092 = 'MISMATCH' or Atl-Sql-093 = 'MISMATCH'
					or Atl-Sql-096 = 'MISMATCH' or Atl-Sql-097 = 'MISMATCH' or Atl-Sql-098 = 'MISMATCH'
					or Ams-Sql-100 = 'MISMATCH' or Ams-Sql-100 = 'MISMATCH'
					or Lhr-Sql-100 = 'MISMATCH' or Lhr-Sql-100 = 'MISMATCH'
					or Pdx-Sql-100 = 'MISMATCH' or Pdx-Sql-101 = 'MISMATCH' or Pdx-Sql-102 = 'MISMATCH' or Pdx-Sql-103 = 'MISMATCH'
			then 'mismatched in: ' +
				case when Web20 = 'MISMATCH' then 'Web20, ' else '' end +
				case when Web22 = 'MISMATCH' then 'Web22, ' else '' end +
				case when Web25 = 'MISMATCH' then 'Web25, ' else '' end +
				case when sqldb26 = 'MISMATCH' then 'sqldb26, ' else '' end +
				case when sqldb27 = 'MISMATCH' then 'sqldb27, ' else '' end +
				case when sqldb32 = 'MISMATCH' then 'sqldb32, ' else '' end +
				case when sqldb35 = 'MISMATCH' then 'sqldb35, ' else '' end +
				case when sqldb36 = 'MISMATCH' then 'sqldb36, ' else '' end +
			--	case when sqldb39 = 'MISMATCH' then 'sqldb39, ' else '' end +
				case when sqldb40 = 'MISMATCH' then 'sqldb40, ' else '' end +
				case when sqldb41 = 'MISMATCH' then 'sqldb41, ' else '' end +
				case when sqldb48 = 'MISMATCH' then 'sqldb48, ' else '' end +
				case when sqldb50 = 'MISMATCH' then 'sqldb50, ' else '' end +
				case when sqldb51 = 'MISMATCH' then 'sqldb51, ' else '' end +
				case when sqldm43 = 'MISMATCH' then 'sqldm43, ' else '' end +
				case when Atl-Sdm-044 = 'MISMATCH' then 'Atl-Sdm-044, ' else '' end +
				case when Atl-Sql-090 = 'MISMATCH' then 'Atl-Sql-090, ' else '' end +
				case when Atl-Sql-091 = 'MISMATCH' then 'Atl-Sql-091, ' else '' end +
				case when Atl-Sql-092 = 'MISMATCH' then 'Atl-Sql-092, ' else '' end +
				case when Atl-Sql-093 = 'MISMATCH' then 'Atl-Sql-093, ' else '' end +
				case when Atl-Sql-096 = 'MISMATCH' then 'Atl-Sql-096, ' else '' end +
				case when Atl-Sql-097 = 'MISMATCH' then 'Atl-Sql-097, ' else '' end +
				case when Atl-Sql-098 = 'MISMATCH' then 'Atl-Sql-098, ' else '' end +
				case when Ams-Sql-100 = 'MISMATCH' then 'Ams-Sql-100, ' else '' end +
				case when Ams-Sql-101 = 'MISMATCH' then 'Ams-Sql-101, ' else '' end +
				case when Lhr-Sql-100 = 'MISMATCH' then 'Lhr-Sql-100, ' else '' end +
				case when Lhr-Sql-101 = 'MISMATCH' then 'Lhr-Sql-101, ' else '' end +
				case when Pdx-Sql-100 = 'MISMATCH' then 'Pdx-Sql-100, ' else '' end +
				case when Pdx-Sql-101 = 'MISMATCH' then 'Pdx-Sql-101, ' else '' end +
				case when Pdx-Sql-102 = 'MISMATCH' then 'Pdx-Sql-102, ' else '' end +
				case when Pdx-Sql-103 = 'MISMATCH' then 'Pdx-Sql-103, ' else '' end
			else ''
			end +
		case when
				web20 = 'MISSING' or web22 = 'MISSING' or web25 = 'MISSING' or sqldb26 = 'MISSING' or sqldb27 = 'MISSING'
					or sqldb32 = 'MISSING' or sqldb35 = 'MISSING' or sqldb36 = 'MISSING'
					--or sqldb39 = 'MISSING'
					or sqldb40 = 'MISSING' or sqldb41 = 'MISSING' or sqldb48 = 'MISSING'
					or sqldb50 = 'MISSING' or sqldb51 = 'MISSING' or sqldm43 = 'MISSING' or Atl-Sdm-044 = 'MISSING'
					or Atl-Sql-090 = 'MISSING' or Atl-Sql-091 = 'MISSING' or Atl-Sql-092 = 'MISSING' or Atl-Sql-093 = 'MISSING'
					or Atl-Sql-096 = 'MISSING' or Atl-Sql-097 = 'MISSING' or Atl-Sql-098 = 'MISSING'
					or Ams-Sql-100 = 'MISSING' or Ams-Sql-100 = 'MISSING'
					or Lhr-Sql-100 = 'MISSING' or Lhr-Sql-100 = 'MISSING'
					or Pdx-Sql-100 = 'MISSING' or Pdx-Sql-101 = 'MISSING' or Pdx-Sql-102 = 'MISSING' or Pdx-Sql-103 = 'MISSING'
			then 'missing in: ' +
				case when Web20 = 'MISSING' then 'Web20, ' else '' end +
				case when Web22 = 'MISSING' then 'Web22, ' else '' end +
				case when Web25 = 'MISSING' then 'Web25, ' else '' end +
				case when sqldb26 = 'MISSING' then 'sqldb26, ' else '' end +
				case when sqldb27 = 'MISSING' then 'sqldb27, ' else '' end +
				case when sqldb32 = 'MISSING' then 'sqldb32, ' else '' end +
				case when sqldb35 = 'MISSING' then 'sqldb35, ' else '' end +
				case when sqldb36 = 'MISSING' then 'sqldb36, ' else '' end +
			--	case when sqldb39 = 'MISSING' then 'sqldb39, ' else '' end +
				case when sqldb40 = 'MISSING' then 'sqldb40, ' else '' end +
				case when sqldb41 = 'MISSING' then 'sqldb41, ' else '' end +
				case when sqldb48 = 'MISSING' then 'sqldb48, ' else '' end +
				case when sqldb50 = 'MISSING' then 'sqldb50, ' else '' end +
				case when sqldb51 = 'MISSING' then 'sqldb51, ' else '' end +
				case when sqldm43 = 'MISSING' then 'sqldm43, ' else '' end +
				case when Atl-Sdm-044 = 'MISSING' then 'Atl-Sdm-044, ' else '' end +
				case when Atl-Sql-090 = 'MISSING' then 'Atl-Sql-090, ' else '' end +
				case when Atl-Sql-091 = 'MISSING' then 'Atl-Sql-091, ' else '' end +
				case when Atl-Sql-092 = 'MISSING' then 'Atl-Sql-092, ' else '' end +
				case when Atl-Sql-093 = 'MISSING' then 'Atl-Sql-093, ' else '' end +
				case when Atl-Sql-096 = 'MISSING' then 'Atl-Sql-096, ' else '' end +
				case when Atl-Sql-097 = 'MISSING' then 'Atl-Sql-097, ' else '' end +
				case when Atl-Sql-098 = 'MISSING' then 'Atl-Sql-098, ' else '' end +
				case when Ams-Sql-100 = 'MISSING' then 'Ams-Sql-100, ' else '' end +
				case when Ams-Sql-101 = 'MISSING' then 'Ams-Sql-101, ' else '' end +
				case when Lhr-Sql-100 = 'MISSING' then 'Lhr-Sql-100, ' else '' end +
				case when Lhr-Sql-101 = 'MISSING' then 'Lhr-Sql-101, ' else '' end +
				case when Pdx-Sql-100 = 'MISSING' then 'Pdx-Sql-100, ' else '' end +
				case when Pdx-Sql-101 = 'MISSING' then 'Pdx-Sql-101, ' else '' end +
				case when Pdx-Sql-102 = 'MISSING' then 'Pdx-Sql-102, ' else '' end +
				case when Pdx-Sql-103 = 'MISSING' then 'Pdx-Sql-103, ' else '' end
			else ''
		end as [message]
	into #mismatchedmessages
	from #mismatchedprocedures

	insert into [sqldm43].Synchronize.dbo.errorMessages(ukey_website, errorSource, errorMessage)
	select
		0 as ukey_website,
		'Procedure missing or mismatched across SQL nodes ' + cast(cast(getDate() as date) as varchar(500)) + '.' as errorSource,
		'Procedure "' + objectName + '" in "' + databasename + '" is ' + left([message], len([message]) -1) as ErrorMessage
	from #mismatchedmessages
	where isnull(message, '') <> ''

	drop table #mismatchedprocedures
	drop table #mismatchedmessages
end
GO
