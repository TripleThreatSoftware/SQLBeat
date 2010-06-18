SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[pr_job_delete] (@nUkeyJob int)
as
begin
	declare @cConversationHandle uniqueidentifier

	select top 1
		@cConversationHandle = conversationHandle
		from jobs (nolock)
		where ukey = @nUkeyJob

	IF EXISTS (SELECT * FROM sys.conversation_endpoints WHERE conversation_handle = @cConversationHandle)
		END CONVERSATION @cConversationHandle

	update jobs with (rowlock) set conversationHandle = null, nextRun = null, isEnabled = 0 where ukey = @nUkeyJob

	delete from jobSteps with (rowlock) where ukey_job = @nUkeyJob
	delete from jobSchedules with (rowlock) where ukey_job = @nUkeyJob
	delete from jobHistory with (rowlock) where ukey_job = @nUkeyJob

	delete from jobs with (rowlock) where ukey = @nUkeyJob
end
