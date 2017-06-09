alter table [fact_weblogs_20170607] drop constraint PK_fact_weblogs_20170607
GO
alter table [fact_weblogs_20170607] ADD  CONSTRAINT [PK_fact_weblogs_20170607] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
