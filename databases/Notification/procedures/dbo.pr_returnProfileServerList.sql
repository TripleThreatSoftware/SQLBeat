SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_returnProfileServerList 'test'
create procedure [dbo].[pr_returnProfileServerList] (@cMachineID varchar(100))
as
begin
	declare @results table (ukey int identity, ukey_server int, serverName varchar(200))

	insert into @results (serverName, ukey_server) values ('All Profile Servers', 0)

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
