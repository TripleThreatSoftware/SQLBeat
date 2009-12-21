use [notification]
go
alter table dm_servers add checkExecutionStats bit default 0
go
update dm_servers set checkExecutionStats = 0
go
update dm_servers set checkExecutionStats = 1 where servername = 'web03'
go
