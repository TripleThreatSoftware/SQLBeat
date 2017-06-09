alter table [fact_weblogs_20170531] drop constraint PK_fact_weblogs_20170531
GO
alter table [fact_weblogs_20170531] ADD  CONSTRAINT [PK_fact_weblogs_20170531] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
