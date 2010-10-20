/****** Object:  StoredProcedure [dbo].[pr_returnServerList]    Script Date: 10/20/2010 11:53:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_returnServerList 'test'
CREATE procedure [dbo].[pr_returnServerList] (@cMachineID varchar(100))
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
GO
