alter table [fact_weblogs_20170609] drop constraint PK_fact_weblogs_20170609
GO
alter table [fact_weblogs_20170609] ADD  CONSTRAINT [PK_fact_weblogs_20170609] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
