create procedure [dbo].[pr_addJobSchedule] (@nUkeyJob int, @nHourStart int = -1, @nMinuteStart int = -1, @nEveryMinutes int = -1)
as
begin
	insert into jobSchedules (ukey_job, hourStart, minuteStart, everyMinutes) values (@nUkeyJob, @nHourStart, @nMinuteStart, @nEveryMinutes)
end
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
