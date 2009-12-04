/****** Object:  StoredProcedure [dbo].[pr_mart_userAgent]    Script Date: 12/04/2009 18:51:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--create table mart_userAgent_byday (ukey int identity, ymd dateTime, ukey_site int, ukey_userAgent bigint, uniques bigint, requests bigint, pageViews bigint,
--	pageRequests bigint, pageNotFoundErrors bigint)
-- drop table mart_browser_byday

create procedure [dbo].[pr_mart_userAgent] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
--	declare @dStartDate dateTime, @dEndDate dateTime
--	set @dStartDate = '2008-02-10'
--	set @dEndDate = '2008-02-11'

	delete from mart_userAgent_byday with (rowlock)
		where ymd >= @dStartDate
			and ymd < dateAdd(day, 1, @dEndDate)

	select
		a.ukey,
		a.ukey_userAgent,
		e.isPage,
		a.requestStatus,
		a.ukey_site,
		convert(varchar(10), ymd, 120) as ymd_trimmed,
		ymd,
		case
			when isnull(appSessionID, '') <> '' then appSessionID
			when isnull(sessionID, '') <> '' then sessionID
			else convert(varchar(20), ukey_clientIP)
			end +
			convert(varchar(20), ukey_userAgent) as uniqueID

		into #weblogdetail

		from v_fact_weblogs_all a
		join dm_uriStem e (nolock) on a.ukey_uriStem = e.ukey

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

	insert into mart_userAgent_byday (ymd, ukey_site, ukey_userAgent, uniques, requests, pageViews, pageRequests, pageNotFoundErrors)
	select
		ymd_trimmed as ymd,
		ukey_site,
		ukey_userAgent,
		count(distinct uniqueID) as uniques,
		count(ukey) as requests,
		sum(case when isPage = 1 and requestStatus <> '404' then 1 else 0 end) as pageviews,
		sum(case when isPage = 1 then 1 else 0 end) as pageRequests,
		sum(case when requestStatus = '404' then 1 else 0 end) as pageNotFoundErrors

		from #weblogdetail

		group by ymd_trimmed, ukey_site, ukey_userAgent

	drop table #weblogdetail
end
GO
