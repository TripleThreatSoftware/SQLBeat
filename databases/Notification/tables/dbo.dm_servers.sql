alter table dm_servers add checkOrphanedUsers bit default 1
GO
update dm_servers set checkOrphanedUsers = 0
GO
