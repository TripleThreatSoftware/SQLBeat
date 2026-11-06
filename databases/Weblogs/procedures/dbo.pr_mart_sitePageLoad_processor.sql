/****** Object:  StoredProcedure [dbo].[pr_mart_sitePageLoad_processor]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_mart_sitePageLoad_processor 'Weblogs201804', 'fact_weblogs_20180401'
CREATE procedure [dbo].[pr_mart_sitePageLoad_processor] (@cDatabaseName varchar(100) = null, @cTableName varchar(100) = null)
as
BEGIN

	declare @nUkeyPost bigint
	declare @nUkeyGet bigint
	declare @cSQLString nvarchar(4000)
	declare @dStartDate dateTime

	if isnull(@cDatabaseName, '') = '' or isnull(@cTableName, '') = ''
	begin
		print 'Missing database or table name parameters...'
		return
	end

	print @cDatabaseName + '.dbo.' + @cTableName

	set @nUkeyPost = (select top 1 ukey from weblogs..dm_method (nolock) where method = 'POST')
	set @nUkeyGet = (select top 1 ukey from weblogs..dm_method (nolock) where method = 'GET')

	create table #results (
		ymd dateTime,
		siteName varchar(500),
		hostName varchar(500),
		isHuman bit,
		ukey_uristem bigint,
		ukey_useragent bigint,
		requestStatus varchar(20),
		numRequests int,
		uniques int,
		pageLoadTime int,
		getTime int,
		postTime int,
		numRequestsOver5 int,
		numRequestsOver25 int
	)

	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	set @dStartDate = getDate()

	set @cSQLString = '
		select
			convert(varchar(10), ymd, 120) as ymd,
			siteName,
			hostName,
			cast(null as bit) as isHuman,
			ukey_uriStem,
			ukey_userAgent,
			requestStatus,
			count(*) as numRequests,
			count(distinct
				case
					when isnull(appSessionID, '''') <> ''''
						then appSessionID
					when isnull(sessionID, '''') <> ''''
						then sessionID
					else convert(varchar(20), ukey_clientIP)
				end + convert(varchar(20), ukey_userAgent)
			) as uniques,
			avg(timeTaken) as pageLoadTime,
			avg(case when ukey_method = ' + cast(@nUkeyGet as varchar(10)) + ' then timeTaken else null end) as getTime,
			avg(case when ukey_method = ' + cast(@nUkeyPost as varchar(10)) + ' then timeTaken else null end) as postTime,
			count(case when ukey_method = ' + cast(@nUkeyGet as varchar(10)) + ' and requestStatus = 200 and timeTaken >= 5000 and timeTaken < 25000 then 1 else null end) as numRequestsOver5,
			count(case when ukey_method = ' + cast(@nUkeyGet as varchar(10)) + ' and requestStatus = 200 and timeTaken >= 25000 then 1 else null end) as numRequestsOver25
		from ' + @cDatabaseName + '.dbo.' + @cTableName + ' (nolock)
		group by
			convert(varchar(10), ymd, 120),
			siteName,
			hostName,
			ukey_uriStem,
			ukey_userAgent,
			requestStatus'

	-- Added in the above numRequestsOver5 & numRequestsOver25 for SLA reporting.
	-- This change added about 2 hours to the total run time for 3 days. From 3 to 5 hours.
	-- Might have to change this due to performance issues.
	-- JReed - 04.04.18

	--print @cSQLString
	--return

	insert into #results
	exec sp_executeSQL @cSQLString

	print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ' ms : insert into temp table #results'

	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	set @dStartDate = getDate()

	create index ix_tmp_ukey_userAgent on #results (ukey_userAgent) with fillfactor = 80

	update a
		set a.isHuman = b.isHuman
	from #results as a
		inner join dm_userAgent (nolock) as b
			on a.ukey_userAgent = b.ukey

	print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ' ms : tag isHuman (#results)'

	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	set @dStartDate = getDate()

	select distinct ukey_uristem into #usedURIs from #results

	print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ' ms : build temp table #usedURIs with '+ cast(@@rowcount as varchar(20)) + ' rows'

	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	set @dStartDate = getDate()

	select
		b.ukey,
		left(b.uriStem, 900) as uriStem,
		cast(null as varchar(100)) as friendlyPageName
	into #pagesUsed
	from #usedURIs a
		inner join weblogs..dm_uristem (nolock) as b
			on a.ukey_uriStem = b.ukey
				and (right(b.uristem, 3) in ('htm') or right(b.uristem, 4) in ('html', 'aspx'))
	where b.isPage = 1

	create index ix_tmp_uriStem on #pagesUsed (uriStem) with fillfactor = 80

	print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ' ms : build temp table #pagesUsed with '+ cast(@@rowcount as varchar(20)) + ' rows'

	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	set @dStartDate = getDate()

	update #pagesUsed
		set friendlyPageName = uriStem
	where uriStem in ('/cart.aspx', '/browseAccessories.aspx', '/showAssembly.aspx', '/productDetails.aspx', '/landingPage.aspx', '/findDealer.aspx', '/checkout_step1.aspx', '/checkout_step2.aspx', '/checkout_thanks.aspx', '/checkout_step3.aspx')

	update #pagesUsed
		set friendlyPageName = '/productDetails.aspx'
	where friendlyPageName is null
		and (uriStem like '/products/%' or uriStem like '/p/%' or uriStem like '/productDetails%')

	update #pagesUsed
		set friendlyPageName = '/refineCar.aspx'
	where friendlyPageName is null
		and (uriStem like '/cars/%html' or uriStem like '/s/%')

	update #pagesUsed
		set friendlyPageName = '/showAssembly.aspx'
	where friendlyPageName is null
		and (uriStem like '/a/%html')

	update #pagesUsed
		set friendlyPageName = '/showAssembly.aspx'
	where friendlyPageName is null
		and (uriStem like '/showAssembly%')

	update #pagesUsed
		set friendlyPageName = '/accessories.aspx'
	where friendlyPageName is null
		and (uriStem like '/g/%' or uriStem like '/accessories%')

	update #pagesUsed
		set friendlyPageName = '/landingpage.aspx'
	where friendlyPageName is null
		and (uriStem like '/go/%')

	update #pagesUsed
		set friendlyPageName = '/manufacturers.aspx'
	where friendlyPageName is null
		and (uriStem like '/manufacturers/%')

	update #pagesUsed
		set friendlyPageName = 'Policies'
	where friendlyPageName is null
		and (uriStem like '/policies%')

	update #pagesUsed
		set friendlyPageName = '/refineCar.aspx'
	where friendlyPageName is null
		and (uriStem like '/bikes/%html')

	update #pagesUsed
		set friendlyPageName = '/refineCar.aspx'
	where friendlyPageName is null
		and (uriStem like '%refinecar.aspx' or uriStem like '/cars/%')

	update #pagesUsed
		set friendlyPageName = 'Sitemaps'
	where friendlyPageName is null
		and (uriStem like '/sitemaps/%')

	update #pagesUsed
		set friendlyPageName = '/cart.aspx'
	where friendlyPageName is null
		and (uriStem = '/cart.aspx')

	update #pagesUsed
		set friendlyPageName = '/productSearch.aspx'
	where friendlyPageName is null
		and (uriStem like '/categories/%html' or uriStem like '/productSearch%')

	update #pagesUsed
		set friendlyPageName = 'Home'
	where friendlyPageName is null
		and (uriStem like '/default%' or uriStem = '/')

	update #pagesUsed
		set friendlyPageName = 'Home_' +
			case when weblogs.dbo.fn_returnListItem(replace(uriStem, '/', '_'), 1, '_') not in ('', '.html') then 'Make_' else '' end +
			case when weblogs.dbo.fn_returnListItem(replace(uriStem, '/', '_'), 2, '_') not in ('', '.html') then 'Year_' else '' end +
			case when weblogs.dbo.fn_returnListItem(replace(uriStem, '/', '_'), 3, '_') not in ('', '.html') then 'Model_' else '' end +
			case when weblogs.dbo.fn_returnListItem(replace(uriStem, '/', '_'), 4, '_') not in ('', '.html') then 'Category' else '' end
	where friendlyPageName is null
		and (uristem like '/%.html' and charindex('_', uriStem) > 0)

	update #pagesUsed
		set friendlyPageName = left(friendlyPageName, len(friendlyPageName) - 1)
	where right(friendlyPageName, 1) = '_'

	update #pagesUsed
		set friendlyPageName = 'Other'
	where friendlyPageName is null
		and uriStem is not null

	delete from #pagesUsed where friendlyPageName is null

	print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + 'ms : update friendlyPageName'

	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	set @dStartDate = getDate()

	delete ms
		from mart_site_pageLoadTimes_byDay as ms
			inner join #results as r
				on ms.ymd = r.ymd
					and ms.siteName = r.siteName
					and ms.hostName = r.hostName

	print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ' ms : cleared out matching records - ' + cast(@@rowcount as varchar(20)) + ' rows'

	set @dStartDate = getDate()

	insert into mart_site_pageLoadTimes_byDay
		(ymd, siteName, hostName, isHuman, requestStatus, friendlyPageName,
			numRequests, uniques, pageLoadTime, getTime, postTime, numRequestsOver5,
			numRequestsOver25, isMobile)
	select
		r.ymd,
		r.siteName,
		r.hostName,
		r.isHuman,
		r.requestStatus,
		pu.friendlyPageName,
		sum(r.numRequests) as numRequests,
		sum(r.uniques) as uniques,
		sum(r.pageLoadTime * cast(r.numRequests as bigint))  / sum(r.numRequests) as pageLoadTime,
		sum(r.getTime * cast(r.numRequests as bigint))  / sum(r.numRequests) as getTime,
		sum(r.postTime * cast(r.numRequests as bigint))  / sum(r.numRequests) as postTime,
		sum(r.numRequestsOver5) as numRequestsOver5,
		sum(r.numRequestsOver25) as numRequestsOver25,
		case
			when ua.userAgent like '%ipad%'
					or ua.userAgent like '%iphone%'
					or ua.userAgent like '%android%'
					or ua.userAgent like '%playbook%'
					or ua.userAgent like '%blackberry%'
					or ua.userAgent like '%htc%'
					or ua.userAgent like '%nokia%'
				then 1
			else 0
		end as isMobile
		from #results as r
			inner join #pagesUsed as pu
				on r.ukey_uriStem = pu.ukey
			inner join Weblogs.dbo.dm_userAgent as ua
				on r.ukey_useragent = ua.ukey
		group by r.ymd,  r.siteName, r.hostName, r.isHuman, r.requestStatus, pu.friendlyPageName,
			case
				when ua.userAgent like '%ipad%'
						or ua.userAgent like '%iphone%'
						or ua.userAgent like '%android%'
						or ua.userAgent like '%playbook%'
						or ua.userAgent like '%blackberry%'
						or ua.userAgent like '%htc%'
						or ua.userAgent like '%nokia%'
					then 1
				else 0
			end

	print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ' ms : inserted new/updated records - ' + cast(@@rowcount as varchar(20)) + ' rows'

	------------------------------------------------------------------------------
	-- Discussed with Cole and we are only going to keep last 6 months worth of
	-- data.
	-- JReed - 04.03.18
	------------------------------------------------------------------------------
	delete from mart_site_pageLoadTimes_byDay
	where ymd < dateadd(month, -6, getdate())
	------------------------------------------------------------------------------

	drop table #results
END
GO
