alter table [fact_weblogs_201705_week21] drop constraint PK_fact_weblogs_201705_week21
GO
alter table [fact_weblogs_201705_week21] ADD  CONSTRAINT [PK_fact_weblogs_201705_week21] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201705_week18_site_source_ymd on [fact_weblogs_201705_week18] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201705_week19_site_source_ymd on [fact_weblogs_201705_week19] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170528_site_source_ymd on [fact_weblogs_20170528] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201705_week20_site_source_ymd on [fact_weblogs_201705_week20] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170529_site_source_ymd on [fact_weblogs_20170529] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170530_site_source_ymd on [fact_weblogs_20170530] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170531_site_source_ymd on [fact_weblogs_20170531] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201705_week21_site_source_ymd on [fact_weblogs_201705_week21] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
USE [Weblogs201704]
GO
