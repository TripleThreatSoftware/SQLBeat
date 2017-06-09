alter table [fact_weblogs_20170602] drop constraint PK_fact_weblogs_20170602
GO
alter table [fact_weblogs_20170602] ADD  CONSTRAINT [PK_fact_weblogs_20170602] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
