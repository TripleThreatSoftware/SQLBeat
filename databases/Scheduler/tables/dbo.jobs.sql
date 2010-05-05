create table jobs (ukey int identity, ymd dateTime default getDate(), jobName varchar(200), isEnabled bit default 1, nextRun dateTime, lastRun dateTime,
	currentStatus varchar(500), lastRunStatus varchar(8000), lastRunSuccess bit default null, conversationHandle uniqueIdentifier)
GO
