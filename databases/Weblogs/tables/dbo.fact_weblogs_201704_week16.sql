alter table [fact_weblogs_201704_week16] drop constraint PK_fact_weblogs_201704_week16
GO
alter table [fact_weblogs_201704_week16] ADD  CONSTRAINT [PK_fact_weblogs_201704_week16] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
