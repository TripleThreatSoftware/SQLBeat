--create table log_returnSQLServerList (ukey int identity, ymd dateTime default getDate(), machineID varchar(100))
--
--GO

-- exec pr_returnSQLServerList 'test'
ALTER procedure [dbo].[pr_returnSQLServerList] (@cMachineID varchar(100))
as
begin
--	insert into log_returnSQLServerList (machineID) values (@cMachineID)

	declare @results table (ukey int identity, ukey_server int, serverName varchar(200))

	insert into @results (serverName, ukey_server) values ('All Profile SQL Servers', 0)

	insert into @results (ukey_server, serverName)
	select ukey_server, b.serverName
		from serverSelection a
		join notification.dbo.dm_servers b (nolock) on b.ukey = a.ukey_server
			and (b.isSQLBox = 1 or b.isClusterNode = 1)
		where a.machineID = @cMachineID
		order by b.serverName

	select *
		from @results
		order by ukey
end

go
