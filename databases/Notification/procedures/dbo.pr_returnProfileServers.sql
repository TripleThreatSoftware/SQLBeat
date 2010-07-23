-- exec pr_returnProfileServers 1

alter procedure pr_returnProfileServers (@nUkeyProfile int)
as
begin
	select distinct c.serverName, b.ukey_server
		from dm_profiles a
		join dm_profileServers b on a.ukey = b.ukey_profile
		join notification.dbo.dm_servers c on b.ukey_server = c.ukey

		order by c.serverName
end
