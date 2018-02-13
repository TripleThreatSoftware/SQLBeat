--set statistics io on
--exec pr_mart_page '2014-07-13', '2014-07-13'

-- alter table mart_page_byday add friendlyPageName varchar(100)

CREATE procedure [dbo].[pr_mart_page] (@dStartDate dateTime, @dEndDate dateTime)
as
begin

--declare @dStartDate dateTime
--declare @dEndDate dateTime
--set @dStartDate = '2014-07-13'
--set @dEndDate = '2014-07-13'

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

		from v_fact_weblogs_all a (nolock)

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by convert(varchar(10), ymd, 120), datePart(hour, ymd),
			a.ukey_site,
			a.ukey_uriStem,
			a.ukey_userAgent,
			a.requestStatus

	select
		b.ukey, b.uriStem, convert(varchar(8000),
		case
			when b.uriStem in ('/cart.aspx', '/browseAccessories.aspx', '/showAssembly.aspx', '/productDetails.aspx', '/landingPage.aspx', '/findDealer.aspx') then b.uriStem
			when b.uriStem in ('/checkout_step1.aspx', '/checkout_step2.aspx', '/checkout_thanks.aspx') then b.uriStem
			when b.uriStem like '/products/%' or b.uriStem like '/p/%' then '/productDetails.aspx'
			when b.uriStem like '/cars/%html' or b.uriStem like '/s/%' then '/refineCar.aspx'
			when b.uriStem like '/a/%html' then '/showAssembly.aspx'
			when b.uriStem like '/g/%' then '/accessories.aspx'
			when b.uriStem like '/go/%' then '/landingpage.aspx'
			when b.uriStem like '/manufacturers/%' then '/manufacturers.aspx'
			when b.uriStem like '/policies%' then 'Policies'
			when b.uriStem like '/bikes/%html' then '/refineCar.aspx'
			when b.uriStem like '%refinecar.aspx' or b.uriStem like '/cars/%' then '/refineCar.aspx'
			when b.uriStem like '/sitemaps/%' then 'Sitemaps'
			when b.uriStem = '/cart.aspx' then '/cart.aspx'
			when b.uriStem like '/categories/%html' or b.uriStem = '/productSearch.aspx' then '/productSearch.aspx'
			when b.uriStem = '/default.aspx' then '/'
			when uristem like '/%.html' and charindex('_', uriStem) > 0 then '/'
			when b.uriStem like '%.css' then 'CSS'
			else 'Other'
			end) as friendlyPageName
		into #pagesUsed
		from (select distinct ukey_uristem from #results) a
		join dm_uristem b on a.ukey_uriStem = b.ukey
			and b.isPage = 1


-- select * from #pagesUsed where friendlyPageName = 'Other' and uristem like '/%.html' and charindex('_', uriStem) > 0

	insert into mart_page_byday (ukey_site, friendlyPageName, requestStatus, ymd,
		numRequests, numRequests_human,
		uniques, uniques_human, pageLoadTime, getTime, postTime)
	select
		a.ukey_site,
		friendlyPageName,
		a.requestStatus,
		a.ymd,
		sum(numRequests),
		sum(case when c.isHuman = 1 then numRequests else 0 end),
		sum(uniques),
		sum(case when c.isHuman = 1 then uniques else 0 end),
		sum(pageLoadTime * numRequests) / sum(numRequests) as pageLoadTime,
		avg(getTime) as getTime,
		avg(postTime) as postTime

		from #results a
		join #pagesUsed b on a.ukey_uriStem = b.ukey
		join dm_userAgent c on a.ukey_userAgent = c.ukey

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by a.ymd, a.ukey_site, friendlyPageName, a.requestStatus

	drop table #results
	drop table #pagesUsed

end
