create procedure pr_job_stop (@nUkeyJob int)
as
begin
	declare @cConversationHandle uniqueidentifier

	select top 1
		@cConversationHandle = conversationHandle
		from jobs (nolock)
		where ukey = @nUkeyJob

	IF EXISTS (SELECT * FROM sys.conversation_endpoints WHERE conversation_handle = @cConversationHandle)
		END CONVERSATION @cConversationHandle

	update jobs with (rowlock) set conversationHandle = null, nextRun = null, currentStatus = null where ukey = @nUkeyJob
end
GO
