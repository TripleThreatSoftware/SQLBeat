alter table [fact_weblogs_20170603] drop constraint PK_fact_weblogs_20170603
GO
alter table [fact_weblogs_20170603] ADD  CONSTRAINT [PK_fact_weblogs_20170603] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
