alter table [fact_weblogs_20170530] drop constraint PK_fact_weblogs_20170530
GO
alter table [fact_weblogs_20170530] ADD  CONSTRAINT [PK_fact_weblogs_20170530] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
