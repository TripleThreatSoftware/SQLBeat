select * from sysfiles

dbcc shrinkfile(2,1)
dbcc shrinkfile(3,1)


select * from scheduler.. jobs order by jobName
select * from scheduler.. jobsteps where ukey_job = 3 order by stepNumber


select * from scheduler.. jobsteps where ukey_job = 4 order by jobName
delete from scheduler.. jobsteps where ukey_job = 4
delete from scheduler.. jobsteps where ukey = 423


insert into scheduler..jobSteps (ukey_job, stepName, stepDatabase, stepText, stepNumber, isCommand, retryOnFailure, retryTimes, continueOnFailure) values (3, 'configuration_log', 'configuration', 'dbcc shrinkfile(2,1)', 2, 0, 0, 0, 1)
insert into scheduler..jobSteps (ukey_job, stepName, stepDatabase, stepText, stepNumber, isCommand, retryOnFailure, retryTimes, continueOnFailure) values (3, 'configuration_log', 'configuration', 'dbcc shrinkfile(3,1)', 3, 0, 0, 0, 1)

insert into scheduler..jobSteps (ukey_job, stepName, stepDatabase, stepText, stepNumber, isCommand, retryOnFailure, retryTimes, continueOnFailure) values (3, 'Notification_log', 'notification', 'dbcc shrinkfile(2,1)', 4, 0, 0, 0, 1)
insert into scheduler..jobSteps (ukey_job, stepName, stepDatabase, stepText, stepNumber, isCommand, retryOnFailure, retryTimes, continueOnFailure) values (3, 'notification_log_e', 'notification', 'dbcc shrinkfile(3,1)', 5, 0, 0, 0, 1)
