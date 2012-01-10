alter table mart_useragent_byday alter column ukey bigint
GO
sp_who2
xp_readerrorlog
sp_cycle_errorlog

select MIN(ymd), MAX(ymd) from mart_page_byday (nolock)
select MIN(ymd), MAX(ymd) from mart_page_byhour (nolock)

drop table mart_page_byhour_archive
GO
select *
	into mart_page_byhour_archive
	from mart_page_byhour
	where ymd < '2011-12-13'

select MIN(ymd), MAX(ymd) from mart_page_byday_archive (nolock)
select MIN(ymd), MAX(ymd) from mart_page_byhour_archive (nolock)

mart_page_byday_archive

select * from scheduler.dbo.jobSteps where stepText like '%pr_archiveOldData%'
select * from scheduler.dbo.jobHistory where ukey_jobstep = 419
GO
