/****** Object:  Index [ix_fact_weblogs_20170606_ukeySite]    Script Date: 6/9/2017 8:43:04 AM ******/
CREATE NONCLUSTERED INDEX [ix_fact_weblogs_20170606_ukeySite] ON [dbo].[fact_weblogs_20170606]
(
	[ukey_site] ASC,
	[ukey_sourceFile] ASC,
	[ymd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
/****** Object:  Index [PK_fact_weblogs_20170606]    Script Date: 6/9/2017 8:43:09 AM ******/
ALTER TABLE [dbo].[fact_weblogs_20170606] ADD  CONSTRAINT [PK_fact_weblogs_20170606] PRIMARY KEY CLUSTERED
(
	[ymd] ASC,
	[ukey_site] ASC,
	[ukey_sourceFile] ASC,
	[ukey_uriStem] ASC,
	[ukey_clientIP] ASC,
	[ukey_userAgent] ASC,
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
ALTER TABLE [dbo].[fact_weblogs_20170606]  WITH CHECK ADD  CONSTRAINT [fact_weblogs_20170606_ymd] CHECK  (([ymd]>='06/06/2017' AND [ymd]<'2017-06-07'))
GO
ALTER TABLE [dbo].[fact_weblogs_20170606] CHECK CONSTRAINT [fact_weblogs_20170606_ymd]
GO
