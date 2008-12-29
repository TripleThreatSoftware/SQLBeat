alter table dm_servers add pageLifeExpectancyAlertThreshold int default 50
GO
update dm_servers set pageLifeExpectancyAlertThreshold = 50
GO
