alter table dm_servers add isSharepoint bit default 0
GO
update dm_servers set isSharepoint = 1 where serverName like 'prosp%'
GO
