alter table [fact_weblogs_20170608] drop constraint PK_fact_weblogs_20170608
GO
alter table [fact_weblogs_20170608] ADD  CONSTRAINT [PK_fact_weblogs_20170608] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
