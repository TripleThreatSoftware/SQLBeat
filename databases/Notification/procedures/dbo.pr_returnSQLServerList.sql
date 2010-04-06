-- exec pr_returnSQLServerList 'test'
alter procedure pr_returnSQLServerList (@cMachineID varchar(100))
as
begin
	declare @bShowServerName bit

	if (select count(*) from serverSelection where machineID = @cMachineID) = 1
		set @bShowServerName = 0
	else
		set @bShowServerName = 1

	declare @results table (ukey int identity, ukey_server int, serverName varchar(200))

	insert into @results (serverName, ukey_server) values ('All SQL Servers', 0)

	insert into @results (ukey_server, serverName)
	select ukey_server, b.serverName
		from serverSelection a
		join notification.dbo.dm_servers b (nolock) on b.ukey = a.ukey_server
		where a.machineID = @cMachineID
		order by b.serverName

	select *
		from @results
		order by ukey
end
