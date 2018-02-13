-- exec pr_mart_site_page '2018-02-09', '2018-02-09'
CREATE procedure [dbo].[pr_mart_site_page] (@dStartDate dateTime, @dEndDate dateTime)
as
begin


	declare @nUkeyPost int
	declare @nUkeyGet int

	set @nUkeyPost = (select top 1 ukey from dm_method (nolock) where method = 'POST')
	set @nUkeyGet = (select top 1 ukey from dm_method (nolock) where method = 'GET')

	set @dStartDate = convert(varchar(10), @dStartDate, 120)
	set @dEndDate = convert(varchar(10), @dEndDate, 120)

	delete from mart_site_page_byday with (rowlock) where ymd >= @dStartDate and ymd <= @dEndDate

	insert into mart_site_page_byday (websiteURL, numActiveMinutes, bytesDelivered, pageURL, ymd, numRequests, getTime, postTime, getsOver5s, getsOver25s, num4xx, num5xx)
	select
		a.hostname as websiteURL,

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
			when right(uristem, 3) in ('htm') or right(uristem, 4) in ('html', 'aspx') then 'Other'
			else 'Other NonPage'
			end as pageURL,

		convert(varchar(10), a.ymd, 120) as ymd,

		count(distinct convert(Varchar(16), a.ymd, 120)) as numActiveMinutes,
		sum(a.bytes) as bytesDelivered,

		count(*) as numRequests,

		avg(case when ukey_method = @nUkeyGet then timeTaken else null end) as getTime,
		avg(case when ukey_method = @nUkeyPost then timeTaken else null end) as postTime,

		sum(case when ukey_method = @nUkeyGet and a.timeTaken > 5000 then 1 else 0 end) as getsOver5s,
		sum(case when ukey_method = @nUkeyGet and a.timeTaken > 25000 then 1 else 0 end) as getsOver25s,

		sum(case when a.requestStatus like '4%' then 1 else 0 end) as num4XX,
		sum(case when a.requestStatus like '5%' then 1 else 0 end) as num5XX

		from v_fact_weblogs_all a (nolock)

		join dm_uristem b (nolock) on a.ukey_uriStem = b.ukey
			and b.isPage = 1
			and (
				right(b.uristem, 3) in ('htm')
				or right(b.uristem, 4) in ('html', 'aspx')
				)

		join dm_userAgent c (nolock) on a.ukey_userAgent = c.ukey
			and c.isHuman = 1

		where a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)

		group by a.hostname,
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
				when right(uristem, 3) in ('htm') or right(uristem, 4) in ('html', 'aspx') then 'Other'
				else 'Other NonPage'
				end,
			convert(varchar(10), a.ymd, 120)
end
GO
