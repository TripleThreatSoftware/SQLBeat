-- exec pr_rpt_pageLoadTime_detail 1, 20000
create procedure pr_rpt_pageLoadTime_detail (@nUkeySite int, @nLoadTime int)
as
begin

	select *
		into #requests
		from v_fact_weblogs_all a
		where a.ymd >= convert(varchar(10), dateAdd(day, -1, getDate()), 120)
			and ukey_site = @nUkeySite

	delete from #requests where ukey_site <> 1

	select a.ymd, b.uriStem, a.queryString, a.timeTaken, a.ukey_userAgent, a.ukey_method, a.win32status, a.requestStatus, a.requestSubstatus
		from (
			select *
				from #requests a
				where timeTaken > @nLoadTime
			) a
		join dm_uriStem b (nolock) on a.ukey_uriStem = b.ukey
			and b.uriStem not like '%axd'
		order by timeTaken desc

	drop table #requests
end
