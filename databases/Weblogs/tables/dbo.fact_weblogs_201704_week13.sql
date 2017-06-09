alter table [fact_weblogs_201704_week13] drop constraint PK_fact_weblogs_201704_week13
GO
alter table [fact_weblogs_201704_week13] ADD  CONSTRAINT [PK_fact_weblogs_201704_week13] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
