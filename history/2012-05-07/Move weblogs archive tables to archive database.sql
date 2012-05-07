select * into weblogs_archive.dbo.mart_page_byhour_archive from mart_page_byhour_archive
GO
select * into weblogs_archive.dbo.mart_page_byday_archive from mart_page_byday_archive
GO
select * into weblogs_archive.dbo.mart_page_byday_archive1 from mart_page_byday_archive1
GO
select * into weblogs_archive.dbo.mart_page_byhour_archive1 from mart_page_byhour_archive1
GO
select * into weblogs_archive.dbo.dm_uriStem_archive from dm_uriStem_archive
GO
exec sp_rename 'mart_page_byhour_archive', 'deleteme_mart_page_byhour_archive'
GO
exec sp_rename 'mart_page_byday_archive', 'deleteme_mart_page_byday_archive'
GO
exec sp_rename 'mart_page_byday_archive1', 'deleteme_mart_page_byday_archive1'
GO
exec sp_rename 'mart_page_byhour_archive1', 'deleteme_mart_page_byhour_archive1'
GO
exec sp_rename 'dm_uriStem_archive', 'deleteme_dm_uriStem_archive'
GO
