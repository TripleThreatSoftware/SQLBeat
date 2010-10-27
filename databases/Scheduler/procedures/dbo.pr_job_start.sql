SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_job_start] (@nUkeyJob int)
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

	set @dNextRun = (select dbo.fn_returnNextRuntime(@nUkeyJob))
	set @nUkeyJobSchedule = 0

	select top 1
		@cConversationHandle = conversationHandle,
		@dLastRun = lastRun
		from jobs (nolock)
		where ukey = @nUkeyJob

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

	if isnull(@nNextRunSeconds, 0) > 0
	begin
		BEGIN CONVERSATION TIMER (@cConversationHandle) TIMEOUT = @nNextRunSeconds;
		update jobs with (rowlock) set conversationHandle = @cConversationHandle, nextRun = @dNextRun, isEnabled = 1 where ukey = @nUkeyJob
	end
end
