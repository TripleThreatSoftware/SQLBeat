/****** Object:  StoredProcedure [dbo].[pr_dashboard_returnWebsites]    Script Date: 12/04/2009 18:51:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_dashboard_returnWebsites]
as
begin

	select a.*, b.dailyUniques
		from (
			select
				isnull(a.friendlyName, isnull(isnull(a.webServer, '') + '.' + isnull(a.webServerService, ''), ''))  as siteName,
				count(distinct b.webServer) as webServers,
				min(b.minYMD) as minYMD,
				max(b.maxYMD) as maxYMD,
				max(dateAdded) as lastFileLoad,
				count(distinct convert(varchar(10), b.maxYMD, 120)) as numDays,
				count(*) as numFiles
				from dm_sites a (nolock)
				join dm_sourceFiles b (nolock) on a.ukey = b.ukey_site
--					and maxYMD >= dateAdd(month, -1, getDate())
				group by isnull(a.friendlyName, isnull(isnull(a.webServer, '') + '.' + isnull(a.webServerService, ''), ''))
			) a
		left outer join (
			select
				isnull(a.friendlyName, isnull(isnull(a.webServer, '') + '.' + isnull(a.webServerService, ''), ''))  as siteName,
				sum(c.dailyUniques) as dailyUniques
				from dm_sites a (nolock)
				join (
					select ukey_site, avg(uniques) as dailyUniques
						from mart_site_byday
						where ymd >= dateAdd(month, -1, getDate())
						group by ukey_site
					) c on a.ukey = c.ukey_site
				group by isnull(a.friendlyName, isnull(isnull(a.webServer, '') + '.' + isnull(a.webServerService, ''), ''))
			) b on a.siteName = b.siteName
		order by a.siteName

end
GO
