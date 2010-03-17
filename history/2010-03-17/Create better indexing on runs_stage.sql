USE [Configuration]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[runs_stage]') AND name = N'ix_runsStage_compound')
	DROP INDEX [ix_runsStage_compound] ON [dbo].[runs_stage] WITH ( ONLINE = OFF )
go

create index ix_runsStage_group_servername_ymd on runs_stage (ukey_group, serverName, ymd) with fillfactor = 50
go
