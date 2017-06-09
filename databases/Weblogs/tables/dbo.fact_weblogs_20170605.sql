alter table [fact_weblogs_20170605] drop constraint PK_fact_weblogs_20170605
GO
alter table [fact_weblogs_20170605] ADD  CONSTRAINT [PK_fact_weblogs_20170605] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
