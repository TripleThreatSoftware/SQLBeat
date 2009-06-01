alter table dm_servers add checkDatabaseBackups bit default 1
GO
update dm_servers set checkDatabaseBackups = 0
GO
