create table jobHistory (ukey int identity, ymd dateTime default getDate(), ukey_job int, ukey_jobStep int, isError bit default 0,
	stepOutput varchar(8000), runtime bigint)
GO
