SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--set statistics io on
--exec pr_mart_page '2010-02-10', '2010-02-11'

ALTER procedure [dbo].[pr_mart_page] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
	declare @nUkeyPost int
	declare @nUkeyGet int

	set @nUkeyPost = (select top 1 ukey from dm_method (nolock) where method = 'POST')
	set @nUkeyGet = (select top 1 ukey from dm_method (nolock) where method = 'GET')

	set @dStartDate = convert(varchar(10), @dStartDate, 120)
	set @dEndDate = convert(varchar(10), @dEndDate, 120)

	delete from mart_page_byhour with (rowlock) where ymd >= @dStartDate and ymd <= @dEndDate
	delete from mart_page_byday with (rowlock) where ymd >= @dStartDate and ymd <= @dEndDate

	select
		a.ukey_site,
		a.ukey_uriStem,
		a.ukey_userAgent,
		a.requestStatus,
		convert(varchar(10), ymd, 120) as ymd,
		datePart(hour, ymd) as [hour],
		count(*) as numRequests,

		count(distinct
			case
				when isnull(appSessionID, '') <> '' then appSessionID
				when isnull(sessionID, '') <> '' then sessionID
				else convert(varchar(20), ukey_clientIP)
				end +
				convert(varchar(20), ukey_userAgent)
			) as uniques,

		avg(timeTaken) as pageLoadTime,

		avg(case when ukey_method = @nUkeyGet then timeTaken else null end) as getTime,
		avg(case when ukey_method = @nUkeyPost then timeTaken else null end) as postTime

		into #results

		from v_fact_weblogs_all a

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by convert(varchar(10), ymd, 120), datePart(hour, ymd),
			a.ukey_site,
			a.ukey_uriStem,
			a.ukey_userAgent,
			a.requestStatus

	insert into mart_page_byhour (ukey_site, ukey_uriStem, requestStatus, ymd, hour,
		numRequests, numRequests_human,
		uniques, uniques_human, pageLoadTime, getTime, postTime)
	select
		a.ukey_site,
		a.ukey_uriStem,
		a.requestStatus,
		a.ymd,
		a.[hour],
		sum(numRequests) as numRequests,
		sum(case when c.isHuman = 1 then numRequests else 0 end) as numRequests_human,
		sum(uniques) as uniques,
		sum(case when c.isHuman = 1 then uniques else 0 end) as uniques_human,
		sum(pageLoadTime * numRequests) / sum(numRequests) as pageLoadTime,
		avg(getTime) as getTime,
		avg(postTime) as postTime

		from #results a
		join dm_uriStem b on a.ukey_uriStem = b.ukey
			and b.isPage = 1
		join dm_userAgent c on a.ukey_userAgent = c.ukey

		group by a.ymd, a.hour, a.ukey_site, a.ukey_uriStem, a.requestStatus

	insert into mart_page_byday (ukey_site, ukey_uriStem, requestStatus, ymd,
		numRequests, numRequests_human,
		uniques, uniques_human, pageLoadTime, getTime, postTime)

	select
		a.ukey_site,
		a.ukey_uriStem,
		a.requestStatus,
		a.ymd,
		sum(numRequests),
		sum(numRequests_human),
		sum(uniques),
		sum(uniques_human),
		sum(pageLoadTime * numRequests) / sum(numRequests) as pageLoadTime,
		avg(getTime) as getTime,
		avg(postTime) as postTime

		from mart_page_byhour a (nolock)

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by a.ymd,
			a.ukey_site,
			a.ukey_uriStem,
			a.requestStatus

	drop table #results


end
