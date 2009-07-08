select * from dm_sources

alter table dm_sources add ukey_server int
GO
update dm_sources set ukey_server = (select top 1 ukey from notification..dm_servers where servername = 'prospweb01') where ukey = 1
update dm_sources set ukey_server = (select top 1 ukey from notification..dm_servers where servername = 'prospweb02') where ukey = 2
GO
use notification
GO
