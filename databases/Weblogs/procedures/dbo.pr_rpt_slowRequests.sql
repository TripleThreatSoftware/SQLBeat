/****** Object:  StoredProcedure [dbo].[pr_rpt_slowRequests]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_slowRequests '2008-10-21', '2008-10-21'
CREATE procedure [dbo].[pr_rpt_slowRequests]
as
begin

	declare @dStartDate datetime
	declare @dEndDate datetime

	-- lol
	set @dStartDate = convert(varchar(10), getDate(), 120)
	set @dEndDate = dateAdd(second, -1, @dStartDate)
	set @dStartDate = dateadd(day, -1, @dStartDate)

select
	a.bytes, a.cookie, a.hostName, a.queryString, a.referer, a.requestStatus, a.requestSubStatus, a.sessionID, a.siteName, a.timeTaken, a.ukey, c.clientIP, b.uriStem, d.userAgent, a.win32Status, a.ymd
	into #slowRequests
	from v_fact_weblogs_all (nolock) a
	join dm_uriStem b on a.ukey_uriStem = b.ukey
--		and b.uristem not like '%scriptresource.axd%'
--		and b.uriStem not like '%productSearch%'
		and b.uriStem not in ('/robots.txt', '/scriptresource.axd', '/webresource.axd')
		and b.uriStem <> '/'
		and b.isPage = 1
		and b.uriStem not like '%.css%'
	join dm_clientIP c on a.ukey_clientIP = c.ukey
	join dm_userAgent d on a.ukey_userAgent = d.ukey
	where timeTaken > 180000 and
		ymd between @dStartDate and @dEndDate
		and ukey_method = 1
	order by timeTaken desc

select * from #slowrequests order by ymd asc

end
GO
