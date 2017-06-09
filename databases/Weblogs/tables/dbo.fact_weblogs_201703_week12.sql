alter table [fact_weblogs_201703_week12] drop constraint PK_fact_weblogs_201703_week12
GO
alter table [fact_weblogs_201703_week12] ADD  CONSTRAINT [PK_fact_weblogs_201703_week12] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
