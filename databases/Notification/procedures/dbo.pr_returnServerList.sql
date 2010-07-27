SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec pr_returnServerList 'test'
ALTER procedure [dbo].[pr_returnServerList] (@cMachineID varchar(100))
as
begin
	declare @results table (ukey int identity, ukey_server int, serverName varchar(200))

	insert into @results (serverName, ukey_server)
	select distinct servername, ukey
		from notification.dbo.dm_servers
		order by serverName

	select *
		from @results
		order by ukey
end
