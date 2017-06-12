drop index dm_useragent.ix_dm_userAgent
go
drop index dm_useragent.ix_dmUserAgent_ukey_isHuman
go

create clustered index ix_useragent_ukey on dm_useragent (ukey) with fillfactor = 80
go
create index ix_useragent_ukey_inc_useragent_ishuman on dm_useragent (ukey) include (useragent, ishuman) with fillfactor = 80
go
create index ix_useragent_useragent_ukey on dm_useragent (useragent) include (ukey) with fillfactor = 80
go



USE [Weblogs]
GO

/****** Object:  Index [ix_dm_userAgent]    Script Date: 6/12/2017 11:10:03 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_dm_userAgent] ON [dbo].[dm_userAgent]
(
	[userAgent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO


USE [Weblogs]
GO

/****** Object:  Index [ix_dmUserAgent_ukey_isHuman]    Script Date: 6/12/2017 11:10:29 AM ******/
CREATE NONCLUSTERED INDEX [ix_dmUserAgent_ukey_isHuman] ON [dbo].[dm_userAgent]
(
	[ukey] ASC,
	[isHuman] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
