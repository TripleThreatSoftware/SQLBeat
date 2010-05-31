create procedure pr_job_disable (@nUkeyJob int)
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
end
GO
