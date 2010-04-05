create table serverSelection (ukey int identity, ymd dateTime default getDate(), machineID varchar(100), ukey_server int)
GO
insert into serverSelection (machineID, ukey_server)
select 'lixrvf55dlqj5055pcpqgj24', ukey from notification..dm_servers where servername = 'web03'
GO
