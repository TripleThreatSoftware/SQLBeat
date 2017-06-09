alter table [fact_weblogs_20170528] drop constraint PK_fact_weblogs_20170528
GO
alter table [fact_weblogs_20170528] ADD  CONSTRAINT [PK_fact_weblogs_20170528] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
