SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_monitorDatabaseBackups]
as
begin

	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(500)
	declare @bCheckBackups bit
	set @cServerName = ''

	create table #results (serverName varchar(200), dbName varchar(200), backupDate dateTime, backupLocation varchar(500), backupSize bigint)

	while exists (
		select top 1 serverName
			from dm_servers a
--			join dm_serverGroups b on a.ukey_group = b.ukey
--				and b.isProduction = 1
			where detailedCheck = 1
				and isenabled = 1
				and serverName > @cServerName
		)
	begin
		select top 1 @cServerName = serverName, @bCheckBackups = checkDatabaseBackups
			from dm_servers a
--			join dm_serverGroups b on a.ukey_group = b.ukey
--				and b.isProduction = 1
			where detailedCheck = 1
				and isenabled = 1
				and serverName > @cServerName
			order by serverName

		set @cSQLString = '
	declare @dStartDate dateTime
	set @dStartDate = dateAdd(week, -3, getDate())

	select
		''' + @cServerName + ''' as serverName,
		isnull(b.database_name, '''') as dbName ,
		backup_finish_date as backupDate,
		isnull(d.physical_device_name, '''') as backupLocation,
		b.backup_size as backupSize

		from [' + @cServerName + '].msdb.dbo.backupset b
		join [' + @cServerName + '].msdb.dbo.backupmediafamily d on b.media_set_id = d.media_set_id
		where b.database_name not in (''master'', ''model'', ''msdb'', ''tempdb'', ''distribution'', ''aspstate'', ''reportServerTempDB'')
			and b.type = ''D''
			and b.backup_start_date >= @dStartDate'

		insert into #results
		exec sp_executeSQL @cSQLString
	end

	delete #results
		from #results a
		join databaseBackupLog b (nolock) on a.serverName = b.serverName
			and a.dbName = b.dbName
			and isnull(a.backupDate, '') = isnull(b.ymd, '')

	insert into databaseBackupLog (serverName, dbName, ymd, backupLocation, backupSize)
	select serverName, dbName, backupDate, backupLocation, backupSize
		from #results

	select distinct a.serverName, a.dbName
		into #allDatabases
		from databaseFileSizeLog a (nolock)
		join (
			select serverName, max(ymd) as ymd from databaseFileSizeLog (nolock) group by serverName
			) b on a.serverName = b.serverName
			and a.ymd = b.ymd
		where a.dbName not in ('master', 'model', 'msdb', 'tempdb', 'distribution')

	delete #allDatabases
		from #allDatabases a
		left outer join dm_servers b (nolock) on a.serverName = b.serverName
		where isnull(b.checkDatabaseBackups, 0) = 0

	select a.serverName, a.dbName, b.ymd as backupDate
		into #alertResults
		from #allDatabases a
		left outer join (
			select serverName, dbName, max(ymd) as ymd
				from databaseBackupLog (nolock)
				group by serverName, dbName
			) b on a.serverName = b.serverName
			and a.dbName = b.dbName
		where dateDiff(day, b.ymd, getDate()) > 7
			or b.serverName is null

	declare @cSubject varchar(500)
	declare @cMessage varchar(8000)
	declare @nNumDatabases int
	set @cServerName = ''

	while exists (
		select top 1 a.serverName
			from #alertResults a
			where a.serverName > @cServerName
		)
	begin
		select top 1 @cServerName = a.serverName
			from #alertResults a
			where a.serverName > @cServerName
			order by a.serverName

		set @nNumDatabases = (select count(*) from #alertResults where serverName = @cServerName)

		set @cSubject = convert(varchar(20), @nNumDatabases) + ' databases on ' + @cServerName + ' have not been backed up.'
		set @cMessage = '<table><tr><th>Server</th><th>Database</th><th>Last Backup</th></tr>'

		select @cMessage = @cMessage +
			'<tr><td>' + serverName + '</td><td>' + dbName + '</td><td>' + isnull(convert(varchar(20), backupDate, 120), 'N/A') + '</td></tr>'
			from #alertResults
			where serverName = @cServerName
			order by dbName

		set @cMessage = @cMessage + '</table>'

		insert into notificationLog_stage (serverName, severity, subject, message) values (@cServerName, 3, @cSubject, @cMessage)
	end

	drop table #results
	drop table #alertResults
end
