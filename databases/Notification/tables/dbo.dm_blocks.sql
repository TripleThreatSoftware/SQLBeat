create table dm_blocks (ukey int identity, ymd dateTime default getDate(),
	blockTitle varchar(200), blockSummary varchar(500), blockData varchar(500))
GO
