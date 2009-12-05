SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_404Requests 'GAOSA - ScoreCard', null, null
ALTER procedure [dbo].[pr_rpt_404Requests] (@cSiteName varchar(100) = '', @dStartDate dateTime = '', @dEndDate dateTime = '')
as
begin
	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(hour, -48, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	select
		b.friendlyName, uriStem,
		count(*) as numRequests,
		convert(varchar(10), min(ymd), 120) as firstSeen,
		convert(varchar(10), max(ymd), 120) as lastSeen
		from v_fact_weblogs_all a
		join dm_sites b (nolock) on a.ukey_site = b.ukey
			and (b.friendlyName = @cSiteName or isnull(@cSiteName, '') = '')
		join dm_uriStem c (nolock) on a.ukey_uriStem = c.ukey
		where a.requestStatus = 404
			and a.ymd >= @dStartDate
			and a.ymd < dateAdd(day, 1, @dEndDate)
		group by b.friendlyName, uriStem
		having count(*) > 10
		order by b.friendlyName, numRequests desc

end
