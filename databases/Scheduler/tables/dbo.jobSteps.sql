create table jobSteps (ukey int identity, ymd dateTime default getDate(), ukey_job int, stepName varchar(200), stepDatabase varchar(200),
	stepText varchar(8000), stepNumber int, isCommand bit default 0, retryOnFailure bit default 0, retryTimes int default 0,
	lastRun dateTime, lastRunStatus varchar(8000), lastRunSuccess bit default 1, continueOnFailure bit default 1)
GO
