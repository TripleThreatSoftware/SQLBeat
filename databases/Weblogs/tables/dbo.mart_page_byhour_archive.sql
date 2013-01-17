exec sp_rename 'mart_page_byhour_archive', 'mart_page_byhour_archive2'
select top 0 * into mart_page_byhour_archive from mart_page_byhour_archive2

exec sp_rename 'mart_page_byday_archive', 'mart_page_byday_archive2'
select top 0 *  into mart_page_byday_archive from mart_page_byday_archive2

alter table weblogs_archive.dbo.mart_page_byhour_archive alter column ukey bigint
