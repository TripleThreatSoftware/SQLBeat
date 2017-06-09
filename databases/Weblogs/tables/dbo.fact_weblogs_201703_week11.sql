alter table [fact_weblogs_201703_week11] drop constraint PK_fact_weblogs_201703_week11
GO
alter table [fact_weblogs_201703_week11] ADD  CONSTRAINT [PK_fact_weblogs_201703_week11] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
