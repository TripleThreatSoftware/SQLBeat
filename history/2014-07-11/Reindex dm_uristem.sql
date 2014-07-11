USE [Weblogs]
GO

/****** Object:  Index [ix_dm_uriStem_ukey]    Script Date: 7/11/2014 9:24:55 AM ******/
DROP INDEX [ix_dm_uriStem_ukey] ON [dbo].[dm_uriStem] WITH ( ONLINE = OFF )
GO


create clustered index ix_uristem_ukey on dm_uristem (ukey) with fillfactor = 80
go
