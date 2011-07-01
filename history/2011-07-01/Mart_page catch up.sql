select convert(varchar(10), ymd, 120), count(*) from mart_page_byday where ukey_site in (10, 1) and ymd >= '2011-06-01' group by convert(varchar(10), ymd, 120) order by convert(varchar(10), ymd, 120)


exec pr_mart_page '2011-06-06', '2011-06-06'

drop table mart_page_byhour_archive

-- 47692365
select *
	into mart_page_byhour_archive
	from mart_page_byhour (nolock)
	where ymd < dateAdd(month, -2, getDate())
go
delete from mart_page_byhour with (tablock) where ymd < dateAdd(month, -2, getDate())

select top 10 * from mart_page_byhour
exec pr_partitionTableDaily 'mart_page_byhour', 'ymd', 'ukey', 0
