/****** Object:  StoredProcedure [dbo].[pr_monitorDatabaseBackups]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_monitorDatabaseBackups]
as
begin

	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cServerName varchar(500)
	set @cServerName = ''

	create table #results (serverName varchar(200), dbName varchar(200), backupDate dateTime, backupLocation varchar(500), backupSize bigint)

	while exists (
		select top 1 serverName
			from dm_servers a
			join dm_serverGroups b on a.ukey_group = b.ukey
				and b.isProduction = 1
			where detailedCheck = 1
				and isenabled = 1
				and serverName > @cServerName
		)
	begin
		select top 1 @cServerName = serverName
			from dm_servers a
			join dm_serverGroups b on a.ukey_group = b.ukey
				and b.isProduction = 1
			where detailedCheck = 1
				and isenabled = 1
				and serverName > @cServerName
			order by serverName

		set @cSQLString = '
	declare @dStartDate dateTime
	set @dStartDate = dateAdd(week, -3, getDate())

	select
		''' + @cServerName + ''' as serverName,
		isnull(a.[name], '''') as dbName ,
		backup_finish_date as backupDate,
		isnull(d.physical_device_name, '''') as backupLocation,
		c.backup_size as backupSize

		from [' + @cServerName + '].master.dbo.sysdatabases a
		left outer join (
			select database_name, max(backup_set_id) as backup_set_id
				from [' + @cServerName + '].msdb.dbo.backupset
				where type = ''D''
					and backup_start_date >= @dStartDate
				group by database_name
			) b on a.[name] = b.database_name
		left outer join [' + @cServerName + '].msdb.dbo.backupset c on a.[name] = c.database_name
			and b.backup_set_id = c.backup_set_id
			and c.type = ''D''
		left outer join [' + @cServerName + '].msdb.dbo.backupmediafamily d on c.media_set_id = d.media_set_id
		where a.name not in (''master'', ''model'', ''msdb'', ''tempdb'', ''distribution'')'

		insert into #results
		exec sp_executeSQL @cSQLString
	end

	delete
		from #results
		where isnull(backupDate, '') >= dateAdd(day, -7, getDate())

	declare @cSubject varchar(500)
	declare @cMessage varchar(8000)
	declare @nNumDatabases int
	set @cServerName = ''

	while exists (select top 1 serverName from #results where serverName > @cServerName)
	begin
		select top 1 @cServerName = serverName
			from #results
			where serverName > @cServerName
			order by serverName

		set @nNumDatabases = (select count(*) from #results where serverName = @cServerName)

		set @cSubject = convert(varchar(20), @nNumDatabases) + ' databases on ' + @cServerName + ' have not been backed up.'
		set @cMessage =
			left('Server' + space(20), 20) + space(1) +
			left('Database' + space(25), 25) + space(1) +
			left('Last Backup' + space(20), 20) + char(13) +
			replicate('=', 20) + space(1) +
			replicate('=', 25) + space(1) +
			replicate('=', 20) + char(13)

		select @cMessage = @cMessage +
			left(serverName + space(20), 20) + space(1) +
			left(dbName + space(25), 25) + space(1) +
			left(isnull(convert(varchar(20), backupDate, 120), 'N/A') + space(20), 20) + char(13)
			from #results
			where serverName = @cServerName
			order by dbName

		insert into notificationLog_stage (serverName, severity, subject, message) values (@cServerName, 2, @cSubject, @cMessage)
	end

	drop table #results
end
GO
