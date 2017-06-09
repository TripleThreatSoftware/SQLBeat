alter table [fact_weblogs_201705_week20] drop constraint PK_fact_weblogs_201705_week20
GO
alter table [fact_weblogs_201705_week20] ADD  CONSTRAINT [PK_fact_weblogs_201705_week20] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
