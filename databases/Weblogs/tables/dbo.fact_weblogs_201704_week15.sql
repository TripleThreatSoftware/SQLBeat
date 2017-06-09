alter table [fact_weblogs_201704_week15] drop constraint PK_fact_weblogs_201704_week15
GO
alter table [fact_weblogs_201704_week15] ADD  CONSTRAINT [PK_fact_weblogs_201704_week15] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
