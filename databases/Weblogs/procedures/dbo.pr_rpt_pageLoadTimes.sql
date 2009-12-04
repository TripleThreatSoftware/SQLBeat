/****** Object:  StoredProcedure [dbo].[pr_rpt_pageLoadTimes]    Script Date: 12/04/2009 18:51:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_pageLoadTimes] (@cSiteName varchar(100))
as
begin

	declare @cSQLString nvarchar(4000)
	declare @nUkeySite int
	declare @cSiteList varchar(100)

	set @cSiteList = ''
	set @cSQLString = '
	select b.uriStem as [Object], ' + char(13)

	set @nUkeySite = 0

	while exists (
		select top 1 ukey
			from dm_sites
			where ukey > @nUkeySite
				and friendlyName = @cSiteName
				and ukey in (select ukey_site from dm_sourceFiles (nolock) where maxYMD >= dateAdd(week, -1, getDate()))
			order by ukey
		)
	begin
		select top 1
			@nUkeySite = ukey,
			@cSQLString = @cSQLString +
				char(9) + 'max(case when a.ukey_site = ' + convert(varchar(20), ukey) + ' then a.avgTime else null end) as [' + webserver + ' Average], ' + char(13) +
				char(9) + 'max(case when a.ukey_site = ' + convert(varchar(20), ukey) + ' then a.numRequests else null end) as [' + webserver + ' Requests], ' + char(13),
	--			char(9) + 'max(case when a.ukey_site = ' + convert(varchar(20), ukey) + ' then a.totalTime else null end) as [' + webserver + '_totalTime], ' + char(13) +
	--			char(9) + 'max(case when a.ukey_site = ' + convert(varchar(20), ukey) + ' then a.totalTime else null end)/max(case when a.ukey_site = ' + convert(varchar(20), ukey) + ' then a.numRequests else null end) as [' + webserver + '_timePerRequest], ' + char(13),
			@cSiteList = @cSiteList + convert(varchar(20), ukey) + ', '
			from dm_sites (nolock)
			where ukey > @nUkeySite
				and friendlyName = @cSiteName
				and ukey in (select ukey_site from dm_sourceFiles (nolock) where maxYMD >= dateAdd(week, -1, getDate()))
			order by ukey
	end

	set @cSiteList = left(@cSiteList, len(@cSiteList) - 2)

	set @cSQLString = left(@cSQLString, len(@cSQLString) - 3) + '
		from (
			select
				ukey_site, ukey_uriStem,
				count(*) as numRequests,
				sum(timeTaken) as totalTime,
				convert(decimal(10,2), avg(convert(decimal(10,2), timeTaken))) as avgTime
				from v_fact_weblogs_all a
				where ukey_site in (' + @cSiteList + ')
					and ymd >= dateAdd(week, -1, getDate())
				group by ukey_site, ukey_uriStem
			) a
		join dm_uriStem b on a.ukey_uriStem = b.ukey
		group by b.uriStem
		having sum(numRequests) >= 100
		order by b.uriStem'

	print @cSQLString

	exec sp_executeSQL @cSQLString
end
GO
