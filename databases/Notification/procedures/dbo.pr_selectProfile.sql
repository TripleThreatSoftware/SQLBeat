--create table databaseSelection (ukey int identity, ymd dateTime default getDate(), machineID varchar(100), ukey_server int, databaseName varchar(200))
--go


create procedure pr_selectProfile (@cMachineID varchar(100), @nUkeyProfile int)
as
begin
	delete from serverSelection where machineID = @cMachineID
	delete from databaseSelection where machineID = @cMachineID

	if exists (select top 1 ukey from dm_profiles where ukey = @nUkeyProfile and machineID = @cMachineID)
	begin
		insert into serverSelection (machineID, ukey_server)
		select @cMachineID, ukey_server
			from dm_profileServers
			where ukey_profile = @nUkeyProfile

		insert into databaseSelection (machineID, ukey_server, databaseName)
		select @cMachineID, ukey_server, databaseName
			from dm_profileDatabases
			where ukey_profile = @nUkeyProfile
	end
	else
	begin
		-- in this case, we've selected "all"

		insert into serverSelection (machineID, ukey_server)
		select @cMachineID, ukey
			from notification.dbo.dm_servers

		insert into databaseSelection (machineID, ukey_server, databaseName)
		select @cMachineID, c.ukey, a.dbName
			from notification.dbo.databaseFileSizeLog a (nolock)
			join (
				select serverName, max(ymd) as ymd
					from notification.dbo.databaseFileSizeLog (nolock)
					where ymd >= dateAdd(hour, -6, getDate())
					group by serverName
				) b on a.serverName = b.serverName
				and a.ymd = b.ymd
			join notification.dbo.dm_servers c (nolock) on a.serverName = c.serverName
			where a.dbName not in ('msdb', 'master', 'model', 'reportServer')
	end
end
