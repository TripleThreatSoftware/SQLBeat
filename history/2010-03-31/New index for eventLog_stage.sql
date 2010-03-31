USE [Notification]
GO
/****** Object:  Index [ix_eventLog_stage_computerName_message]    Script Date: 03/31/2010 13:33:19 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[eventLog_stage]') AND name = N'ix_eventLog_stage_computerName_message')
	DROP INDEX [ix_eventLog_stage_computerName_message] ON [dbo].[eventLog_stage] WITH ( ONLINE = OFF )
go

create index ix_eventLogStage_computerName_message on eventLog_stage (computerName) include (message) with fillfactor = 50
