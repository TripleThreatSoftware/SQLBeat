alter table dm_servers add indexCheck bit default 0, lastIndexCheck dateTime, indexCheckMinuteInterval int default 15
GO
update dm_servers set indexCheck = 1 where isSQLBox = 1
GO
