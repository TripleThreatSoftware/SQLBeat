alter table [fact_weblogs_201703_week10] drop constraint PK_fact_weblogs_201703_week10
GO
alter table [fact_weblogs_201703_week10] ADD  CONSTRAINT [PK_fact_weblogs_201703_week10] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
