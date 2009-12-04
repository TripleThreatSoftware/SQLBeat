/****** Object:  StoredProcedure [dbo].[pr_mart_page]    Script Date: 12/04/2009 18:51:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--set statistics io on
--exec pr_mart_page '2008-11-09', '2008-11-09'

CREATE procedure [dbo].[pr_mart_page] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
	set @dStartDate = convert(varchar(10), @dStartDate, 120)
	set @dEndDate = convert(varchar(10), @dEndDate, 120)

	delete from mart_page_byhour with (rowlock) where ymd >= @dStartDate and ymd <= @dEndDate
	delete from mart_page_byday with (rowlock) where ymd >= @dStartDate and ymd <= @dEndDate

	insert into mart_page_byhour (ukey_site, ukey_uriStem, requestStatus, ymd, hour,
		numRequests, numRequests_human,
		uniques, uniques_human, pageLoadTime)

	select
		a.ukey_site,
		a.ukey_uriStem,
		a.requestStatus,
		convert(varchar(10), ymd, 120) as ymd,
		datePart(hour, ymd) as [hour],
		count(*) as numRequests,
		sum(case when c.isHuman = 1 then 1 else 0 end) as numRequests_human,

		count(distinct
			case
				when isnull(appSessionID, '') <> '' then appSessionID
				when isnull(sessionID, '') <> '' then sessionID
				else convert(varchar(20), ukey_clientIP)
				end +
				convert(varchar(20), ukey_userAgent)
			) as uniques,

		count(distinct
			case when c.isHuman = 1 then
				case
					when isnull(appSessionID, '') <> '' then appSessionID
					when isnull(sessionID, '') <> '' then sessionID
					else convert(varchar(20), ukey_clientIP)
					end +
					convert(varchar(20), ukey_userAgent)
				else null
				end
			) as uniques_human,
		avg(isnull(timeTaken, 0)) as pageLoadTime

		from v_fact_weblogs_all a
		join dm_uriStem b on a.ukey_uriStem = b.ukey
			and b.isPage = 1
		join dm_userAgent c on a.ukey_userAgent = c.ukey

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by convert(varchar(10), ymd, 120), datePart(hour, ymd),
			a.ukey_site,
			a.ukey_uriStem,
			a.requestStatus

	insert into mart_page_byday (ukey_site, ukey_uriStem, requestStatus, ymd,
		numRequests, numRequests_human,
		uniques, uniques_human, pageLoadTime)

	select
		a.ukey_site,
		a.ukey_uriStem,
		a.requestStatus,
		a.ymd,
		sum(numRequests),
		sum(numRequests_human),
		sum(uniques),
		sum(uniques_human),
		avg(pageLoadTime) as pageLoadTime

		from mart_page_byhour a

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by a.ymd,
			a.ukey_site,
			a.ukey_uriStem,
			a.requestStatus


end
GO
