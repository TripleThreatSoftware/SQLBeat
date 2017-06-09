alter table [fact_weblogs_201705_week19] drop constraint PK_fact_weblogs_201705_week19
GO
alter table [fact_weblogs_201705_week19] ADD  CONSTRAINT [PK_fact_weblogs_201705_week19] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
