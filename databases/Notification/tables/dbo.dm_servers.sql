alter table dm_servers add tableSizeCheck bit default 0, lastTableSizeCheck dateTime, tableSizeCheckMinuteInterval int default 720
GO
update dm_servers set tableSizeCheck = 1, tableSizeCheckMinuteInterval = 720 where isSQLBox = 1
GO
