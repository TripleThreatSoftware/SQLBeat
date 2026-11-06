/****** Object:  StoredProcedure [dbo].[pr_mart_userAgent]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--create table mart_userAgent_byday (ukey int identity, ymd dateTime, ukey_site int, ukey_userAgent bigint, uniques bigint, requests bigint, pageViews bigint,
--	pageRequests bigint, pageNotFoundErrors bigint)
-- drop table mart_browser_byday

CREATE procedure [dbo].[pr_mart_userAgent] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
	--declare @dStartDate dateTime, @dEndDate dateTime
	--set @dStartDate = '2022-08-04'
	--set @dEndDate = '2022-08-05'


	declare @dNow dateTime
	declare @dTimeElapsed dateTime

	set @dStartDate = convert(varchar(10), @dStartDate, 120)
	set @dEndDate = convert(varchar(10), @dEndDate, 120)

	if @dStartDate = @dEndDate
		set @dEndDate = dateadd(day, 1, @dStartDate)

	delete
		from mart_userAgent_byday with (rowlock)
		where ymd >= @dStartDate
			and ymd < @dEndDate

	if object_id('tempdb..#weblogdetail') is not null
		drop table #weblogdetail

	create table #weblogdetail (ymd dateTime, ukey_site int, ukey_useragent bigint, uniqueID varchar(500), requests int, pageviews int, pageRequests int, pageNotFoundErrors int)

	set @dNow = @dStartDate
	while @dNow < @dEndDate
	begin
		-- 57,967,254
		-- 53,587,654

		print @dNow
		set @dTimeElapsed = getDate()

		if object_id('tempdb..#requests') is not null
			drop table #requests

		select
			ymd,
			ukey_site,
			ukey_useragent,
			ukey_uriStem,
			case
				when isnull(appSessionID, '') <> '' then appSessionID
				when isnull(sessionID, '') <> '' then sessionID
				else convert(varchar(20), ukey_clientIP)
				end +
				convert(varchar(20), ukey_userAgent) as uniqueID,
			requestStatus
			into #requests
			from v_fact_weblogs_all a (nolock)
			where a.ymd >= @dNow
				and a.ymd < dateadd(hour, 1, @dNow)
				and a.ymd < @dEndDate

		print convert(varchar(20), datediff(second, @dTimeElapsed, getDate())) + 's: 1'

		insert into #weblogdetail
		select
			convert(varchar(10), a.ymd, 120) as ymd,
			a.ukey_site,
			a.ukey_userAgent,
			a.uniqueID,
			count(*) as requests,
			sum(case when e.isPage = 1 and a.requestStatus <> '404' then 1 else 0 end) as pageviews,
			sum(case when e.isPage = 1 then 1 else 0 end) as pageRequests,
			sum(case when a.requestStatus = '404' then 1 else 0 end) as pageNotFoundErrors

			from #requests a
			join dm_uriStem e (nolock) on a.ukey_uriStem = e.ukey

			group by
				convert(varchar(10), a.ymd, 120),
				a.ukey_site,
				a.ukey_userAgent,
				a.uniqueID

		print convert(varchar(20), datediff(second, @dTimeElapsed, getDate())) + 's: 2'

		set @dNow = dateadd(hour, 2, @dNow)
	end

	insert into mart_userAgent_byday (ymd, ukey_site, ukey_userAgent, uniques, requests, pageViews, pageRequests, pageNotFoundErrors)
	select
		a.ymd as ymd,
		a.ukey_site,
		a.ukey_userAgent,
		count(distinct a.uniqueID) as uniques,
		sum(requests) as requests,
		sum(pageviews) as pageviews,
		sum(pageRequests) as pageRequests,
		sum(pageNotFoundErrors) as pageNotFoundErrors

		from #weblogdetail a
		group by ymd, ukey_site, ukey_userAgent

	drop table #weblogdetail
end
GO
