alter table [fact_weblogs_20170601] drop constraint PK_fact_weblogs_20170601
GO
alter table [fact_weblogs_20170601] ADD  CONSTRAINT [PK_fact_weblogs_20170601] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170602_site_source_ymd on [fact_weblogs_20170602] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170603_site_source_ymd on [fact_weblogs_20170603] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170604_site_source_ymd on [fact_weblogs_20170604] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170605_site_source_ymd on [fact_weblogs_20170605] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170606_site_source_ymd on [fact_weblogs_20170606] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170607_site_source_ymd on [fact_weblogs_20170607] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170608_site_source_ymd on [fact_weblogs_20170608] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170609_site_source_ymd on [fact_weblogs_20170609] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_20170601_site_source_ymd on [fact_weblogs_20170601] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
USE [Weblogs201705]
GO
