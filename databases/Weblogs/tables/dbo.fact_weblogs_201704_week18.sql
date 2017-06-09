alter table [fact_weblogs_201704_week18] drop constraint PK_fact_weblogs_201704_week18
GO
alter table [fact_weblogs_201704_week18] ADD  CONSTRAINT [PK_fact_weblogs_201704_week18] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201704_week13_site_source_ymd on [fact_weblogs_201704_week13] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201704_week14_site_source_ymd on [fact_weblogs_201704_week14] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201704_week15_site_source_ymd on [fact_weblogs_201704_week15] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201704_week16_site_source_ymd on [fact_weblogs_201704_week16] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201704_week17_site_source_ymd on [fact_weblogs_201704_week17] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201704_week18_site_source_ymd on [fact_weblogs_201704_week18] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
USE [Weblogs201703]
GO
