alter table dm_serverJobs add isCurrent bit default 1
update dm_serverJobs set isCurrent = 1
