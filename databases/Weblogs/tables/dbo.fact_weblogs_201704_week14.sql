alter table [fact_weblogs_201704_week14] drop constraint PK_fact_weblogs_201704_week14
GO
alter table [fact_weblogs_201704_week14] ADD  CONSTRAINT [PK_fact_weblogs_201704_week14] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
