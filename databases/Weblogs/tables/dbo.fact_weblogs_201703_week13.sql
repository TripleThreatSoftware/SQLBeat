alter table [fact_weblogs_201703_week13] drop constraint PK_fact_weblogs_201703_week13
GO
alter table [fact_weblogs_201703_week13] ADD  CONSTRAINT [PK_fact_weblogs_201703_week13] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201703_week9_site_source_ymd on [fact_weblogs_201703_week9] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201703_week10_site_source_ymd on [fact_weblogs_201703_week10] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201703_week11_site_source_ymd on [fact_weblogs_201703_week11] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201703_week12_site_source_ymd on [fact_weblogs_201703_week12] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
create index ix_fact_weblogs_201703_week13_site_source_ymd on [fact_weblogs_201703_week13] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80
GO
--select 'alter table [' + a.name + '] ADD  CONSTRAINT [PK_' + a.name + '] PRIMARY KEY CLUSTERED (ymd) with fillfactor = 80'
--	from sysobjects a
--	where a.name like 'fact_weblogs%'
--		and xtype = 'u'

--select 'create index ix_' + a.name + '_site_source_ymd on [' + a.name + '] (ukey_site, ukey_sourcefile, ymd) with fillfactor = 80'
--	from sysobjects a
--	where a.name like 'fact_weblogs%'
--		and xtype = 'u'


--select 'alter table [' + b.name + '] drop constraint ' + a.name
--	from sysindexes a
--	join sysobjects b on a.id = b.id
--	where b.name like 'fact_weblogs%'
--		and a.name like 'pk%'
GO
