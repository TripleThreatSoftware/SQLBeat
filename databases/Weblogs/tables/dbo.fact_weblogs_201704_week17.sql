alter table [fact_weblogs_201704_week17] drop constraint PK_fact_weblogs_201704_week17
GO
alter table [fact_weblogs_201704_week17] ADD  CONSTRAINT [PK_fact_weblogs_201704_week17] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
