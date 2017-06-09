alter table [fact_weblogs_20170604] drop constraint PK_fact_weblogs_20170604
GO
alter table [fact_weblogs_20170604] ADD  CONSTRAINT [PK_fact_weblogs_20170604] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
