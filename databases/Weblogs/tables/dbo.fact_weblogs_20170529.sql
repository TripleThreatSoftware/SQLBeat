alter table [fact_weblogs_20170529] drop constraint PK_fact_weblogs_20170529
GO
alter table [fact_weblogs_20170529] ADD  CONSTRAINT [PK_fact_weblogs_20170529] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
