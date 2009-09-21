-- exec pr_compareDatabases 'mssql-slv2', 'switch_us', 'ppmas027', 'switch_us'

create table synchronizedDatabases (ukey int identity, sourceServer varchar(200), sourceDatabase varchar(200), targetServer varchar(200), targetDatabase varchar(200), lastCheck dateTime)
GO
