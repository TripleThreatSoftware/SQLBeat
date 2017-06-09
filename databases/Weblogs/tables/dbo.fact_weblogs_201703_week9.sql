alter table [fact_weblogs_201703_week9] drop constraint PK_fact_weblogs_201703_week9
GO
alter table [fact_weblogs_201703_week9] ADD  CONSTRAINT [PK_fact_weblogs_201703_week9] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
