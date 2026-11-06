/****** Object:  StoredProcedure [dbo].[pr_alert_iiserrors]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_alert_iiserrors]
as
begin

	select top 0 * into #errors from v_fact_weblogs_all

	declare @dToday dateTime
	declare @cSQLString nvarchar(4000)
	declare @cSubject varchar(500)
	declare @cBody varchar(2000)
	declare @cServername varchar(100)
	declare @nUkey int

	set @dToday = convert(varchar(10), dateadd(week, -1, getDate()), 120)

	-- 11 minutes
	insert into #errors
	select *
		from v_fact_weblogs_all (nolock)
		where left(requestStatus, 1) in ('4', '5')
			and not sitename = 'parked'
			and ymd >= @dToday

	-- drop table #results
	select top 50
		d.webServer,
		case when a.ukey_method = 1 then 'GET' else 'POST' end as method,
		c.uriStem, a.requestStatus,
		count(*) as numErrors,
		avg(timetaken) as timeTaken,
		count(distinct sitename) as numSites,
		min(sitename) as site1,
		max(sitename) as site2,
		min(useragent) as useragent1,
		max(useragent) as useragent2,
		min(case when queryString <> '-' then queryString else null end) as queryString1,
		max(queryString) as queryString2,
		min(case when referer <> '-' then referer else null end) as referer1,
		max(referer) as referer2,
		identity(int) as ukey
		into #results
		from #errors a
		join dm_userAgent b (nolock) on a.ukey_useragent = b.ukey
			and (b.isHuman = 1 or b.useragent like '%bingbot%' or b.useragent like '%google%')
		join dm_uristem c (nolock) on a.ukey_uriStem = c.ukey
			and not uriStem like '/manage/%'

		join dm_sites d (nolock) on a.ukey_site = d.ukey

		where not (sitename = 'AppSecure' and uristem = '/')
			and not siteName in ('SIMPLEDANCE', 'TRIPLETHREATSOFTWARE', 'AppHome', 'SQLBEAT')
			and not c.uriStem in ('/favicon.ico')
			and not c.uriStem like '%/images/parts/%'
			and not c.uriStem like '%/images/maps/%'
			and not c.uriStem like '%.axd'
			and not c.uriStem like '%.php'
			and not c.uriStem like '%robots.txt'
			and not c.uriStem like '%.txt'
			and not c.uriStem like '%.txt'
			and not c.uriStem like '%.xml'
			and not c.uriStem like '%.json'
			and not c.uriStem like '%/errors/%'
			and not c.uriStem like '%apple-touch%'
			and not (c.uriStem like '%aspx' and requestStatus = '500')	-- for now, let's focus on missing assets
			and not (c.uriStem in ('/productDetails.aspx', '/default.aspx', '/browseaccessories.aspx') and requestStatus = '404')
		group by d.webServer, c.uriStem, a.requestStatus, case when a.ukey_method = 1 then 'GET' else 'POST' end
		having count(*) > 100
		order by count(*) desc

	-- select * from #results
	-- select top 100 * from #errors
	-- select * from dm_sites where ukey = 105

	--declare @cSubject varchar(500)
	--declare @cBody varchar(2000)
	--declare @cServername varchar(100)
	--declare @nUkey int

	--declare @dToday dateTime
	--set @dToday = convert(varchar(10), dateadd(day, -3, getDate()), 120)

	set @nUkey = 0

	while exists (select top 1 ukey from #results where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@cServername = webserver,
			@cSubject = convert(varchar(10), @dToday, 120) + ' (wk) : ' +
				case when requestStatus = '404' and not uriStem like '%aspx%' then 'Missing Asset : ' else '' end +
				notification.dbo.fn_returnFormattedInt(numErrors) + ' errors' + ' : ' + method + '/' + requestStatus + ' "' + uriStem + '". '  ,
			@cBody = left(
				'URI: ' + uriStem + '<br>' +
				'Error: ' + requestStatus + '<br>' +
				'Occurences: ' + notification.dbo.fn_returnFormattedInt(numErrors) + '<br>' +
				'Method: ' + method + '<br>' +
				'Time Taken (avg): ' + convert(varchar(20), timeTaken) + 'ms<br>' +
				'Nodes: ' + convert(varchar(20), numSites) + '<br>' +
				'Node1: ' + site1 + '<br>' +
				'Node2: ' + site2 + '<br>' +
				'Querystring1: ' + isnull(Querystring1, 'N/A') + '<br>' +
				'Querystring2: ' + isnull(Querystring2, 'N/A') + '<br>' +
				'Referer1: ' + isnull(Referer1, 'N/A') + '<br>' +
				'Referer2: ' + isnull(Referer2, 'N/A') + '<br>',
				8000)
				from #results
				where ukey > @nUkey
				order by ukey

		--print @cServername
		--print @cSubject
		--print @cBody

		exec notification.dbo.pr_sendMessage '', 'DBA', @cSubject, @cBody
	end

	drop table #results
	drop table #errors
end
GO
