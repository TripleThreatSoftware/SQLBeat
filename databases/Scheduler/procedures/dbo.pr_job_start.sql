create procedure pr_job_start (@nUkeyJob int)
as
begin
	declare @cConversationHandle uniqueidentifier
	declare @dNextRun dateTime
	declare @dLastRun dateTime
	declare @dThisNextRun dateTime
	declare @nHourStart int
	declare @nMinuteStart int
	declare @nEveryMinutes int
	declare @nNextRunSeconds bigint
	declare @nUkeyJobSchedule int

	set @dNextRun = null
	set @nUkeyJobSchedule = 0

	select top 1
		@cConversationHandle = conversationHandle,
		@dLastRun = lastRun
		from jobs (nolock)
		where ukey = @nUkeyJob

	while exists (select top 1 ukey from jobSchedules (nolock) where ukey_job = @nUkeyJob and ukey > @nUkeyJobSchedule)
	begin

		select top 1
			@nHourStart = hourStart,
			@nMinuteStart = minuteStart,
			@nEveryMinutes = everyMinutes,
			@nUkeyJobSchedule = ukey
			from jobSchedules (nolock)
			where ukey_job = @nUkeyJob
				and ukey > @nUkeyJobSchedule
			order by ukey

		if isnull(@nEveryMinutes, 0) > 0
			if @dLastRun is not null and dateAdd(minute, @nEveryMinutes, @dLastRun) > getDate()
				set @dThisNextRun = dateAdd(minute, @nEveryMinutes, @dLastRun)
			else
				set @dThisNextRun = dateAdd(second, 10, getDate())
		else
		begin
			if dateAdd(minute, @nMinuteStart, dateAdd(hour, @nHourStart, convert(varchar(10), getDate(), 120))) > getDate()
				set @dThisNextRun = dateAdd(minute, @nMinuteStart, dateAdd(hour, @nHourStart, convert(varchar(10), getDate(), 120)))
			else
				set @dThisNextRun = dateAdd(minute, @nMinuteStart, dateAdd(hour, @nHourStart, convert(varchar(10), dateAdd(day, 1, getDate()), 120)))
		end

--		print 'This next runtime: ' + convert(varchar(20), @dThisNextRun, 120)

		-- if there are multiple schedules, find the next runtime
		if @dThisNextRun < @dNextRun or isnull(@dNextRun, '') = ''
			set @dNextRun = @dThisNextRun
	end

	if @cConversationHandle is null
	begin
		BEGIN DIALOG CONVERSATION @cConversationHandle
			FROM SERVICE   [//ScheduledJobService]
			TO SERVICE      '//ScheduledJobService',
							'CURRENT DATABASE'
			ON CONTRACT     [//ScheduledJobContract]
			WITH ENCRYPTION = OFF;
	end

	set @nNextRunSeconds = dateDiff(second, getDate(), @dNextRun)

	BEGIN CONVERSATION TIMER (@cConversationHandle) TIMEOUT = @nNextRunSeconds;

	update jobs with (rowlock) set conversationHandle = @cConversationHandle, nextRun = @dNextRun, isEnabled = 1 where ukey = @nUkeyJob
end
GO
