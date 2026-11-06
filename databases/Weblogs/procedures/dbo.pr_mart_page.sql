/****** Object:  StoredProcedure [dbo].[pr_mart_page]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--set statistics io on
-- exec pr_mart_page '2024-01-02', '2024-01-02'

-- alter table mart_page_byday add friendlyPageName varchar(100)

CREATE procedure [dbo].[pr_mart_page] (@dStartDate dateTime, @dEndDate dateTime)
as
begin

--declare @dStartDate dateTime
--declare @dEndDate dateTime
--set @dStartDate = '2024-01-01'
--set @dEndDate = '2024-01-01'

	declare @nUkeyPost int
	declare @nUkeyGet int
	declare @dToday dateTime
	declare @dStart dateTime
	declare @dEnd dateTime
	declare @nRowcount int
	declare @cDatabaseName varchar(100)
	declare @cTableName varchar(100)
	declare @cSQLString nvarchar(4000)

	set @nUkeyPost = (select top 1 ukey from dm_method (nolock) where method = 'POST')
	set @nUkeyGet = (select top 1 ukey from dm_method (nolock) where method = 'GET')

	set @dStartDate = convert(varchar(10), @dStartDate, 120)
	set @dEndDate = convert(varchar(10), @dEndDate, 120)

	if @dStartDate = @dEndDate
		set @dEndDate = dateAdd(day, 1, @dStartDate)

--	delete from mart_page_byhour with (rowlock) where ymd >= @dStartDate and ymd < @dEndDate
	delete from mart_page_byday with (rowlock) where ymd >= @dStartDate and ymd < @dEndDate

	create table #results (ukey_site int, ukey_uristem bigint, ukey_useragent bigint, requestStatus varchar(500), ymd dateTime, numRequests bigint, numGet bigint, numPost bigint, uniques int, pageLoadTime int, getTime int, postTime int) --, hour int

	set @dToday = @dStartDate

	while @dToday < @dEndDate
	begin
--		print 'Processing ' + convert(varchar(20), @dToday, 120)

		insert into fact_weblogs_stage_hist (stepName) values ('PR_MART_PAGE - ' + 'BEGIN: Processing ' + convert(varchar(20), @dToday, 120))

		set @dStart = @dToday
		set @dEnd = dateadd(day, 1, @dStart)

		set @cDatabaseName = 'weblogs' + convert(varchar(4), datepart(year, @dStart)) + right('00' + convert(varchar(2), datepart(month, @dStart)), 2)
		set @cTableName = 'fact_weblogs_' + convert(varchar(4), datepart(year, @dStart)) + right('00' + convert(varchar(2), datepart(month, @dStart)), 2) + right('00' + convert(varchar(2), datepart(day, @dStart)), 2)

		set @cSQLString = '
		insert into #results
		select
			a.ukey_site,
			a.ukey_uriStem,
			a.ukey_userAgent,
			a.requestStatus,
			''' + convert(varchar(10), @dStart, 120) + ''' as ymd,
			count(*) as numRequests,
			sum(case when ukey_method = ' + convert(varchar(20), @nUkeyGet) + ' then 1 else 0 end) as numGet,
			sum(case when ukey_method = ' + convert(varchar(20), @nUkeyPost) + ' then 1 else 0 end) as numPost,

			count(distinct
				case
					when isnull(appSessionID, '''') <> '''' then appSessionID
					when isnull(sessionID, '''') <> '''' then sessionID
					else convert(varchar(20), ukey_clientIP)
					end +
					convert(varchar(20), ukey_userAgent)
				) as uniques,

			avg(timeTaken) as pageLoadTime,

			avg(case when ukey_method = ' + convert(varchar(20), @nUkeyGet) + ' then timeTaken else null end) as getTime,
			avg(case when ukey_method = ' + convert(varchar(20), @nUkeyPost) + ' then timeTaken else null end) as postTime

			from [' + @cDatabaseName + '].dbo.[' + @cTableName + '] a (nolock)
			join dm_clientIP b (nolock) on a.ukey_clientIP = b.ukey
				and (b.isBlocked = 0 or b.isBlocked is null)

--			where ukey_site = 319

			group by
				a.ukey_site,
				a.ukey_uriStem,
				a.ukey_userAgent,
				a.requestStatus'

		begin try
			-- take a shot at the raw table
			print @cSQLString
			exec sp_executeSQL @cSQLString
		end try
		begin catch
			insert into fact_weblogs_stage_hist (stepName) values ('PR_MART_PAGE - Unable to hit table directly. ' + error_message())

			-- if the table doesn't exist, hit the view instead
			insert into #results
			select
				a.ukey_site,
				a.ukey_uriStem,
				a.ukey_userAgent,
				a.requestStatus,
				@dStart as ymd,
				count(*) as numRequests,
				sum(case when ukey_method = @nUkeyGet then 1 else 0 end) as numGet,
				sum(case when ukey_method = @nUkeyPost then 1 else 0 end) as numPost,

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

				from v_fact_weblogs_all a (nolock)
				join dm_clientIP b (nolock) on a.ukey_clientIP = b.ukey
					and (b.isBlocked = 0 or b.isBlocked is null)

				where a.ymd >= @dStart and a.ymd < @dEnd
--					and ukey_site = 319
				group by
					convert(varchar(10), ymd, 120),
					a.ukey_site,
					a.ukey_uriStem,
					a.ukey_userAgent,
					a.requestStatus
		end catch

		set @nRowcount = @@rowcount

		insert into fact_weblogs_stage_hist (stepName) values ('PR_MART_PAGE - ' + 'END: Processing ' + convert(varchar(20), @dToday, 120) + ' (' + convert(varchar(20), @nRowcount) + ')')
		set @dToday = dateAdd(day, 1, @dToday)
	end

	-- drop table #allPages
	select ukey_uristem, count(*) as numHits
		into #allPages
		from #results
		group by ukey_uristem

	set @nRowcount = @@rowcount
	insert into fact_weblogs_stage_hist (stepName) values ('PR_MART_PAGE - Identified all URIs (' + convert(varchar(20), @nRowcount) + ')')

	-- drop table #pagesUsed
	select
		b.ukey,
		b.uriStem,
		convert(varchar(100), null) as friendlyPageName,
		sum(numHits) as numHits
		into #pagesUsed
		from #allPages a
		join dm_uristem b (nolock) on a.ukey_uriStem = b.ukey
			and b.isPage = 1
		group by b.ukey, b.uriStem

	set @nRowcount = @@rowcount
	insert into fact_weblogs_stage_hist (stepName) values ('PR_MART_PAGE - Identified pages (' + convert(varchar(20), @nRowcount) + ')')

	update #pagesUsed
		set friendlyPageName = left(
			case
				when uristem in ('/checkout_step1.aspx', '/checkout_step2.aspx', '/checkout_thanks.aspx', '/productDetails.aspx', '/default.aspx', '/showAssembly.aspx',
					'/cart.aspx', '/landingpage.aspx', '/productSearch.aspx', '/findDealer.aspx', '/parttype.aspx', '/', '/browseaccessories.aspx', '/manage/recentorders.aspx', '/manage/home.aspx', '/manage/login.aspx') then uristem
				when uristem like '%/AjaxGlobalTranslations' then 'AjaxGlobalTranslations'
				when uristem like '%/GetUserVehicles' then 'GetUserVehicles'
				when uristem like '%/GetInterpretForModal' then 'GetInterpretForModal'
				when uristem like '%/GetSmartSearchResults' then 'GetSmartSearchResults'
				when uristem like '%/InsertVehicle' then 'InsertVehicle'
				when uristem like '%/GetHotspots' then 'GetHotspots'
				when uristem like '%/GetInterpretForMyGarage' then 'GetInterpretForMyGarage'
				when uristem like '%/GetInterpretForRedirect' then 'GetInterpretForRedirect'
				when uristem like '%/AsyncRefineSearch' then 'AsyncRefineSearch'
				when uristem like '%/RemoveUserVehicles' then 'RemoveUserVehicles'
				when uristem like '%/CreateVinLinks' then 'CreateVinLinks'
				when uristem like '%/GetPartTypeResults' then 'GetPartTypeResults'
				when uristem like '%/UpdateUserVehicles' then 'UpdateUserVehicles'
				when uristem like '%/ReturnCartContents' then 'ReturnCartContents'
				when uristem like '%/ReturnCartNumItems' then 'ReturnCartNumItems'
				when uristem like '%/ReturnCartNumberItems' then 'ReturnCartNumberItems'
				when uristem like '%/ReturnCartSummary' then 'ReturnCartSummary'
--				when uristem like '%/GetPartTypeResults' then ''
--				when uristem like '%/GetPartTypeResults' then ''
				when uristem like '%/RecordAction.ashx' then 'RecordAction'
				when uristem like '/products/%' or uristem like '/p/%' then '/productDetails.aspx'
				when uristem like '/cars/%html' or uristem like '/s/%' then '/refineCar.aspx'
				when uristem like '/a/%html' then '/showAssembly.aspx'
				when uristem like '/g/%' or uriStem like '/accessories%' then '/browseaccessories.aspx'
				when uristem like '/go/%' then '/landingpage.aspx'
				when uristem like '/manufacturers/%' then '/manufacturers.aspx'
				when uristem like '/policies%' then 'Policies'
				when uristem like '/bikes/%html' then '/refineCar.aspx'
				when uristem like '%refinecar.aspx' or uristem like '/cars/%' then '/refineCar.aspx'
				when uristem like '/sitemaps/%' then 'Sitemaps'
				when uristem = '/cart.aspx' then '/cart.aspx'
				when uristem like '/categories/%html' or uristem = '/productSearch.aspx' then '/productSearch.aspx'
				when uristem = '/default.aspx' then '/'
				when uristem like '/%.html' and charindex('_', uriStem) > 0 then '/'
				when uristem like '%.css' then 'CSS'
				when uristem like '%.woff%' or uristem like '%.ttf' or uristem like '%.eot' or uristem like '%/fonts/%' then 'Font'
				when uristem like '%.ico' then 'FavIco'
				when uriStem like '/errors%' then uriStem
	--			when uristem like '%.php' then 'Hack Attempt'
				else 'Other'
				end, 100)

	set @nRowcount = @@rowcount
	insert into fact_weblogs_stage_hist (stepName) values ('PR_MART_PAGE - Friendly page names set (' + convert(varchar(20), @nRowcount) + ')')

--if suser_sname() like '%admin%'
--	select * from #pagesUsed where friendlyPageName = 'Other' order by numHits desc

	--alter table mart_page_byday add numGet bigint, numPost bigint
-- select * from #pagesUsed where friendlyPageName = 'Other' and uristem like '/%.html' and charindex('_', uriStem) > 0

	insert into mart_page_byday (ukey_site, friendlyPageName, requestStatus, ymd,
		numRequests, numRequests_human,
		uniques, uniques_human, pageLoadTime, getTime, postTime, numGet, numPost)
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
		sum(getTime * numGet) / sum(numGet) as getTime,
		sum(postTime * numPost) / sum(numPost) as postTime,
		sum(numGet) as numGet,
		sum(numPost) as numPost

		from #results a
		join #pagesUsed b on a.ukey_uriStem = b.ukey
		join dm_userAgent c (nolock) on a.ukey_userAgent = c.ukey

--		where friendlyPageName = '/productDetails.aspx'
--			and ukey_site = 319

		--where a.ymd >= @dStartDate
		--	and a.ymd < dateAdd(day, 1, @dEndDate)

		group by a.ymd, a.ukey_site, friendlyPageName, a.requestStatus

	set @nRowcount = @@rowcount
	insert into fact_weblogs_stage_hist (stepName) values ('PR_MART_PAGE - Inserted Results (' + convert(varchar(20), @nRowcount) + ')')

	drop table #results
	drop table #pagesUsed
	drop table #allPages

end
GO
