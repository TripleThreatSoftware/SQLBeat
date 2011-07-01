declare @dStartDate dateTime, @dEndDate dateTime



	declare @nUkeyPost int
	declare @nUkeyGet int

	set @nUkeyPost = (select top 1 ukey from dm_method (nolock) where method = 'POST')
	set @nUkeyGet = (select top 1 ukey from dm_method (nolock) where method = 'GET')

	set @dStartDate = '2011-06-06'
	set @dEndDate = '2011-06-06'

set statistics io on

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

		into #finalData

		from #results a
		join dm_uriStem b on a.ukey_uriStem = b.ukey
			and b.isPage = 1
		join dm_userAgent c on a.ukey_userAgent = c.ukey

		group by a.ymd, a.hour, a.ukey_site, a.ukey_uriStem, a.requestStatus
