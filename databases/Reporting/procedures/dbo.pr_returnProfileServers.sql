/****** Object:  StoredProcedure [dbo].[pr_returnProfileServers]    Script Date: 10/20/2010 11:53:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_returnProfileServers 1

CREATE procedure [dbo].[pr_returnProfileServers] (@nUkeyProfile int)
as
begin
	select distinct c.serverName, b.ukey_server
		from dm_profiles a
		join dm_profileServers b on a.ukey = b.ukey_profile
		join notification.dbo.dm_servers c on b.ukey_server = c.ukey

		order by c.serverName
end
GO
