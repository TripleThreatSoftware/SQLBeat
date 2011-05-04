select top 10 * from mart_page_byday

create table mart_page_byday_archive (ukey int, ukey_site int, ukey_uristem int, requestStatus int, ymd dateTime, numRequests int, numRequests_human int,
	uniques int, uniques_human int, pageLoadTime int, pagePostTime int, getTime int, postTime int)
go

insert into mart_page_byday_archive (ukey, ukey_site, ukey_uristem, requestStatus, ymd, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime)
select ukey, ukey_site, ukey_uristem, requestStatus, ymd, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime
	from mart_page_byday (nolock)
	where ymd < dateAdd(month, -3, getDate())

delete from mart_page_byday with (tablock) where ymd < dateAdd(month, -3, getDate())
