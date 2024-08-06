/****** Object:  StoredProcedure [dbo].[pr_AppDb_compareDatabaseObjects]    Script Date: 8/6/2024 11:41:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec pr_AppDb_compareDatabaseObjects 1
CREATE procedure [dbo].[pr_AppDb_compareDatabaseObjects](@bPreviewResults bit = 0)
as
begin
	declare @cSourceDBServer varchar(200)

	set @cSourceDBServer = 'sqldb39'

	create table #dbServers (ukey int identity, serverName varchar(200))
	insert into #dbServers (serverName)
	values ('web20'), ('web25'), ('sqldb36'), ('sqldb41'), ('sqldb48'), ('sqldm43'), ('sqldb50'), ('sqldb51'),
		('Atl-Sql-081'), ('Atl-Sql-082'), ('Atl-Sql-083'), ('Atl-Sql-084'), ('Atl-Sql-085'), ('Atl-Sql-086'),
		('Atl-Sql-090'), ('Atl-Sql-091'), ('Atl-Sql-092'), ('Atl-Sql-093'),
		('Atl-Sql-096'), ('Atl-Sql-097'), ('Atl-Sql-098'), ('Atl-Sdm-044'),
		('Ams-Sql-100'), ('Ams-Sql-101'),
		('Lhr-Sql-100'), ('Lhr-Sql-101'),
		('Pdx-Sql-100'), ('Pdx-Sql-101'), ('Pdx-Sql-102'), ('Pdx-Sql-103')

	----************************************************************************
	---- used for troubleshooting
	--select a.serverName, b.max_lastSeen
	--	from #dbServers a with (nolock)
	--	left join (select servername, max(ymd_lastSeen) max_lastSeen
	--				from auditData_objectText with (nolock)
	--				where serverName in (select distinct serverName from #dbServers)
	--				group by servername
	--			) b on a.serverName = b.serverName
	--	order by b.max_lastSeen


	--select *
	--	from notification.dbo.dm_servers with (nolock)
	--	where objectChangeCheck = 1
	--		and isEnabled = 1
	--	order by servername

	--select *
	--	from auditData_objectText with (nolock)
	--	where databasename = 'AppDb_master'
	--		and objectname = 'fn_returnPlacementDynamicText'
	--		and xtype = 'TF'
	--		and isCurrent = 1

	----************************************************************************

	select distinct a.servername, a.databaseName, a.objectName, a.xtype
		into #mismatch
		-- select a.*
		from (
			select distinct b.servername, a.databaseName, a.objectName, a.xtype, a.textChecksum, a.colID
				from auditData_objectText a (nolock)
				, (select distinct servername
						from auditData_objectText (nolock)
						where serverName in
							(select distinct serverName from #dbServers)
					) b
				where a.serverName = @cSourceDBServer
					and a.databaseName in ('AppDb', 'AppDb_Lite', 'AppDb_Master', 'AppDb_a', 'AppDb_b', 'AppDb_sourcedata_a', 'AppDb_sourcedata_b', 'geolocation', 'geolocation_a', 'geolocation_b')
					and a.isCurrent = 1
					and not a.objectName like '%tmp%'
					and not a.objectName like '%temp%'
					and not a.objectName like '%old%'
					and not a.objectName like '%test%'
					and not a.objectName like '%dott%'
					and not a.objectName like '%notused'
					and not a.objectName like '%2'
					and not a.objectName like 'DF_%'
					and not (a.objectName like 'lk_website_%' and a.xtype = 'V')
					and not a.objectName like '%pr_client%'
					and not (a.databaseName like '%sourcedata%' and a.xtype = 'P')
					and not a.xtype = 'V'
			) a
		left outer join auditData_objectText b (nolock) on a.servername = b.servername
			and a.databaseName = b.databaseName
			and a.objectName = b.objectName
			and a.xtype = b.xtype
			and a.textChecksum = b.textChecksum
			and a.colID = b.colID
			and b.isCurrent = 1
		where b.ukey is null
			and not (
				a.databaseName in ('AppDb_a', 'AppDb_b', 'AppDb_sourcedata', 'AppDb_sourcedata_a', 'AppDb_sourcedata_b')
				and a.xtype in ('P', 'FN', 'TF')
				)

--select * from auditData_indexes where indexName = 'ix_productCategories_website_category_product' and databaseName = 'AppDb_a' order by servername, keyNumber

	insert into #mismatch
	select distinct a.serverName, a.databaseName, a.tableName + '.' + a.indexName, 'IX' as xtype
		from (
			select distinct b.servername, a.databaseName, a.tableName, a.indexName, a.columnName
				from auditData_indexes a (nolock)
				, (select distinct servername
						from auditData_indexes (nolock)
						where serverName in
							(select distinct serverName from #dbServers)
					) b
				where a.serverName = @cSourceDBServer
					and a.databaseName in ('AppDb', 'AppDb_Lite', 'AppDb_Master', 'AppDb_a', 'AppDb_b', 'AppDb_sourcedata_a', 'AppDb_sourcedata_b', 'geolocation', 'geolocation_a', 'geolocation_b')
					and a.isCurrent = 1
					and not tableName like 'queue%'
					and not tableName like 'sqlagent%'
			) a
		left outer join auditData_indexes b (nolock) on a.servername = b.servername
			and a.databaseName = b.databaseName
			and a.indexName = b.indexName
			and a.tableName = b.tableName
			and a.columnName = b.columnName
			and b.isCurrent = 1

		where b.ukey is null
			and not a.indexName like 'PK%'	-- these are all bogus

	delete from #mismatch
		where databaseName in ('AppDb_a', 'AppDb_b')
			and (serverName like 'Ams%' or serverName like 'Lhr%')

	--select * from #mismatch

	if isnull(@bPreviewResults, 0) = 1
	begin
		select
			a.databaseName,
			a.objectName,
			a.xtype,
			max(case when servername = 'web20' then 'X' else '' end) as [web20],
			max(case when servername = 'web25' then 'X' else '' end) as [web25],
			max(case when servername = 'sqldb36' then 'X' else '' end) as [sqldb36],
			max(case when servername = 'sqldb41' then 'X' else '' end) as [sqldb41],
			max(case when servername = 'sqldb48' then 'X' else '' end) as [sqldb48],
			max(case when servername = 'sqldb50' then 'X' else '' end) as [sqldb50],
			max(case when servername = 'sqldb51' then 'X' else '' end) as [sqldb51],
			max(case when servername = 'sqldm43' then 'X' else '' end) as [sqldm43],
			max(case when servername = 'Atl-Sdm-044' then 'X' else '' end) as [Atl-Sdm-044],
			max(case when servername = 'Atl-Sql-081' then 'X' else '' end) as [Atl-Sql-081],
			max(case when servername = 'Atl-Sql-082' then 'X' else '' end) as [Atl-Sql-082],
			max(case when servername = 'Atl-Sql-083' then 'X' else '' end) as [Atl-Sql-083],
			max(case when servername = 'Atl-Sql-084' then 'X' else '' end) as [Atl-Sql-084],
			max(case when servername = 'Atl-Sql-085' then 'X' else '' end) as [Atl-Sql-085],
			max(case when servername = 'Atl-Sql-086' then 'X' else '' end) as [Atl-Sql-086],
			max(case when servername = 'Atl-Sql-090' then 'X' else '' end) as [Atl-Sql-090],
			max(case when servername = 'Atl-Sql-091' then 'X' else '' end) as [Atl-Sql-091],
			max(case when servername = 'Atl-Sql-092' then 'X' else '' end) as [Atl-Sql-092],
			max(case when servername = 'Atl-Sql-093' then 'X' else '' end) as [Atl-Sql-093],
			max(case when servername = 'Atl-Sql-096' then 'X' else '' end) as [Atl-Sql-096],
			max(case when servername = 'Atl-Sql-097' then 'X' else '' end) as [Atl-Sql-097],
			max(case when servername = 'Atl-Sql-098' then 'X' else '' end) as [Atl-Sql-098],
			max(case when servername = 'Ams-Sql-100' then 'X' else '' end) as [Ams-Sql-100],
			max(case when servername = 'Ams-Sql-101' then 'X' else '' end) as [Ams-Sql-101],
			max(case when servername = 'Lhr-Sql-100' then 'X' else '' end) as [Lhr-Sql-100],
			max(case when servername = 'Lhr-Sql-101' then 'X' else '' end) as [Lhr-Sql-101],
			max(case when servername = 'Pdx-Sql-100' then 'X' else '' end) as [Pdx-Sql-100],
			max(case when servername = 'Pdx-Sql-101' then 'X' else '' end) as [Pdx-Sql-101],
			max(case when servername = 'Pdx-Sql-102' then 'X' else '' end) as [Pdx-Sql-102],
			max(case when servername = 'Pdx-Sql-103' then 'X' else '' end) as [Pdx-Sql-103]
			from #mismatch a
			group by a.databaseName, a.xtype, a.objectName
			order by a.databaseName, a.xtype, a.objectName
	end
	else
	begin
		declare @nRowCount int
		declare @cSubject varchar(500)
		declare @cBody varchar(max)

		set @nRowCount = (select count(*) from (select distinct databasename, objectname, xtype from #mismatch) a)
		set @cSubject = 'SQL Mismatch : ' + convert(varchar(20), @nRowCount) + ' objects at ' + convert(varchar(16), getDate(), 120)
		set @cBody =
			'<table>' +
				'<tr>' +
				'<th>Database</th><th>Object</th><th>Type</th>' +
				'<th>web20</th>' +
				'<th>web25</th>' +
				'<th>sqldb36</th>' +
				'<th>sqldb41</th>' +
				'<th>sqldb48</th>' +
				'<th>sqldb50</th>' +
				'<th>sqldb51</th>' +
				'<th>sqldm43</th>' +
				'<th>Atl-Sdm-044</th>' +
				'<th>Atl-Sql-081</th>' +
				'<th>Atl-Sql-082</th>' +
				'<th>Atl-Sql-083</th>' +
				'<th>Atl-Sql-084</th>' +
				'<th>Atl-Sql-085</th>' +
				'<th>Atl-Sql-086</th>' +
				'<th>Atl-Sql-090</th>' +
				'<th>Atl-Sql-091</th>' +
				'<th>Atl-Sql-092</th>' +
				'<th>Atl-Sql-093</th>' +
				'<th>Atl-Sql-096</th>' +
				'<th>Atl-Sql-097</th>' +
				'<th>Atl-Sql-098</th>' +
				'<th>Ams-Sql-100</th>' +
				'<th>Ams-Sql-101</th>' +
				'<th>Lhr-Sql-100</th>' +
				'<th>Lhr-Sql-101</th>' +
				'<th>Pdx-Sql-100</th>' +
				'<th>Pdx-Sql-101</th>' +
				'<th>Pdx-Sql-102</th>' +
				'<th>Pdx-Sql-103</th>' +
				'</tr>'

		select @cBody = @cBody +
			'<tr align="center"><td>' + a.databaseName + '</td><td>' + a.objectName + '</td><td>' + a.xtype + '</td><td>' +
			max(case when a.servername = 'web20' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'web25' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'sqldb36' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'sqldb41' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'sqldb48' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'sqldb50' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'sqldb51' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'sqldm43' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sdm-044' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-081' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-082' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-083' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-084' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-085' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-086' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-090' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-091' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-092' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-093' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-096' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-097' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Atl-Sql-098' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Ams-Sql-100' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Ams-Sql-101' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Lhr-Sql-100' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Lhr-Sql-101' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Pdx-Sql-100' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Pdx-Sql-101' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Pdx-Sql-102' then 'X' else '' end) + '</td><td>' +
			max(case when a.servername = 'Pdx-Sql-103' then 'X' else '' end) + '</td><td>' +
			'</tr>'
			from #mismatch a
			group by a.databaseName, a.xtype, a.objectName
			order by a.databaseName, a.xtype, a.objectName

		set @cBody = @cBody + '</table>'

		print @cSubject
		print @cBody

		exec notification.dbo.pr_sendMessage 'alerts@example.com', 'alerts@example.com', @cSubject, @cBody, 1
	end

	drop table #mismatch
end
GO
