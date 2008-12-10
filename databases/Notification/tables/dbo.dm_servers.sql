alter table dm_servers add connectionAlertThreshold int
GO
alter table dm_servers add activeConnectionAlertThreshold int
GO
update dm_servers set connectionAlertThreshold = 340, activeConnectionAlertThreshold = 100
GO
