alter table [fact_weblogs_201705_week18] drop constraint PK_fact_weblogs_201705_week18
GO
alter table [fact_weblogs_201705_week18] ADD  CONSTRAINT [PK_fact_weblogs_201705_week18] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
