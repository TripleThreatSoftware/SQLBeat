USE [Weblogs]
GO
/****** Object:  StoredProcedure [dbo].[pr_alert_fileErrorRate]    Script Date: 08/20/2008 10:56:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_alert_fileErrorRate]
as
begin

	declare @dStartDate_then dateTime
	declare @dEndDate_then dateTime
	declare @dStartDate_now dateTime
	declare @dEndDate_now dateTime

	set @dEndDate_now = dateAdd(hour, -12, convert(varchar(10), getDate(), 120))
	set @dStartDate_now = dateAdd(day, -7, @dEndDate_now)

	set @dEndDate_then = dateAdd(day, -7, @dStartDate_now)
	set @dStartDate_then = dateAdd(day, -7, @dEndDate_then)

	select ukey_site, ukey_uriStem,
		count(*) as numSeen,
		min(ymd) as firstSeen,
		max(ymd) as lastSeen
		into #errorsSeen_then
		from v_fact_weblogs_all
		where requestStatus = '404'
			and ymd >= @dStartDate_then
			and ymd < dateAdd(day, 1, @dEndDate_then)
		group by ukey_site, ukey_uriStem

	select ukey_site, ukey_uriStem,
		count(*) as numSeen,
		min(ymd) as firstSeen,
		max(ymd) as lastSeen
		into #errorsSeen_now
		from v_fact_weblogs_all
		where requestStatus = '404'
			and ymd >= @dStartDate_now
			and ymd < dateAdd(day, 1, @dEndDate_now)
		group by ukey_site, ukey_uriStem

	select a.friendlyName, d.uriStem,
		dateDiff(hour, a.firstSeen, a.lastSeen) as hours_then,
		convert(decimal(20,6), convert(decimal(20,6), a.numRequests) / convert(decimal(20,6), dateDiff(hour, a.firstSeen, a.lastSeen))) as errorsPerHour_then,
		convert(decimal(20,6), convert(decimal(20,6), a.numRequests) / convert(decimal(20,6), e.totalRequests)) as errorsPerRequest_then,

		a.numRequests as numThen, b.numRequests as numNow,
		dateDiff(hour, b.firstSeen, b.lastSeen) as hours_now,
		convert(decimal(20,6), convert(decimal(20,6), b.numRequests) / convert(decimal(20,6), dateDiff(hour, b.firstSeen, b.lastSeen))) as errorsPerHour_now,
		convert(decimal(20,6), convert(decimal(20,5), b.numRequests) / convert(decimal(20,6), f.totalRequests)) as errorsPerRequest_now

		into #urlErrors
		from (
			select
				c.friendlyName, ukey_uriStem,
				sum(numSeen) as numRequests,
				convert(varchar(10), min(firstSeen), 120) as firstSeen,
				convert(varchar(10), max(lastSeen), 120) as lastSeen
				from #errorsSeen_then a
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and c.friendlyName like 'PRO%'
				group by c.friendlyName, ukey_uriStem
				having sum(numSeen) > 200
			) a
		left outer join (
			select
				c.friendlyName, ukey_uriStem,
				sum(numSeen) as numRequests,
				convert(varchar(10), min(firstSeen), 120) as firstSeen,
				convert(varchar(10), max(lastSeen), 120) as lastSeen
				from #errorsSeen_now a
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and c.friendlyName like 'PRO%'
				group by c.friendlyName, ukey_uriStem
			) b on a.friendlyName = b.friendlyName
				and a.ukey_uriStem = b.ukey_uriStem

		join dm_uriStem d (nolock) on a.ukey_uriStem = d.ukey

		join (
			select c.friendlyName, sum(requests) as totalRequests
				from mart_site_byday a
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and c.friendlyName like 'PRO%'
				where ymd >= @dStartDate_then
					and ymd <= @dEndDate_then
				group by c.friendlyName
				having sum(requests) > 0
			) e on a.friendlyName = e.friendlyName
		join (
			select c.friendlyName, sum(requests) as totalRequests
				from mart_site_byday a
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and c.friendlyName like 'PRO%'
				where ymd >= @dStartDate_now
					and ymd <= @dEndDate_now
				group by c.friendlyName
				having sum(requests) > 0
			) f on a.friendlyName = f.friendlyName

		where dateDiff(hour, a.firstSeen, a.lastSeen) > 0
			and dateDiff(hour, b.firstSeen, b.lastSeen) > 0
			and f.totalRequests <> 0

	select *
		into #results
		from (
			select *
				, (errorsPerHour_now - errorsPerHour_then) / errorsPerHour_then as errorsPerHour_delta,
				(errorsPerRequest_now - errorsPerRequest_then) / errorsPerRequest_then as errorsPerRequest_delta
				from #urlErrors a
				where errorsPerHour_then <> 0
					and errorsPerRequest_then <> 0
			) a
		where (errorsPerHour_delta < -.25 and errorsPerRequest_delta < -.25)
			or (errorsPerHour_delta > .25 and errorsPerRequest_delta > .25)
			or abs(errorsPerHour_delta) > .75
			or abs(errorsPerRequest_delta) > .75
			or errorsPerHour_now >= 5

	declare @cFriendlyName varchar(200)
	declare @cMessage varchar(8000)
	declare @cSubject varchar(500)
	set @cFriendlyName = ''

	while exists (select top 1 friendlyName from #results where friendlyName > @cFriendlyName)
	begin
		select top 1 @cFriendlyName = friendlyName
			from #results
			where friendlyName > @cFriendlyName
			order by friendlyName

		select @cSubject = '404 errors for week ending ' + convert(varchar(10), @dEndDate_now, 120) + '.'
			from #results
			where friendlyName = @cFriendlyName

		set @cMessage = '404s from the period ' +
			convert(varchar(10), @dStartDate_then, 120) + ':' + convert(varchar(10), @dEndDate_then, 120) + ' ' +
			'were compared to ' +
			convert(varchar(10), @dStartDate_now, 120) + ':' + convert(varchar(10), @dEndDate_now, 120) + ' ' +
			'and a significant change in the rate of 404 errors was observed for the following objects: ' + char(13) + char(13)

		set @cMessage = @cMessage +
			left('' + space(40), 40) + '|' +
			left(' Errors per Hour' + space(17), 17) + '|' +
			left('Errors per Request' + space(19), 19) + '|' +
			left('   Rate Change' + space(17), 17) + space(1) + char(13) +

			left('URL' + space(40), 40) + '|' +
			left('Then' + space(20), 8) + space(1) +
			left('Now' + space(20), 8) + '|' +
			left('Then' + space(20), 9) + space(1) +
			left('Now' + space(20), 9) + '|' +

			left('Per Hour' + space(20), 8) + space(1) +
			left('Per Req' + space(20), 8) + char(13) +

			replicate('=', 40) + '|' +
			replicate('=', 8) + space(1) +
			replicate('=', 8) + '|' +
			replicate('=', 9) + space(1) +
			replicate('=', 9) + '|' +
			replicate('=', 8) + space(1) +
			replicate('=', 8) + char(13)

		select @cMessage = @cMessage +
			left(isnull(uriStem, '') + space(40), 40) + space(1) +

			right(space(8) + isnull(convert(varchar(8), convert(decimal(8,3), errorsPerHour_then)), ''), 8) + space(1) +
			right(space(8) + isnull(convert(varchar(8), convert(decimal(8,3), errorsPerHour_now)), ''), 8) + space(1) +

			right(space(9) + isnull(convert(varchar(9), convert(decimal(8,6), errorsPerRequest_then)), ''), 9) + space(1) +
			right(space(9) + isnull(convert(varchar(9), convert(decimal(8,6), errorsPerRequest_now)), ''), 9) + space(1) +

			right(space(8) + isnull(convert(varchar(8), convert(decimal(8,3), errorsPerHour_delta * 100)), '') + '%', 8) + space(1) +
			right(space(8) + isnull(convert(varchar(8), convert(decimal(8,3), errorsPerRequest_delta * 100)), '') + '%', 8) + space(1) + char(13)

			from #results
			where friendlyName = @cFriendlyName
			order by uriStem

		insert into notification..notificationLog_stage (serverName, subject, message, severity) values (@cFriendlyName, @cSubject, @cMessage, 2)

		print @cSubject
		print @cMessage

	end

	drop table #results
	drop table #urlErrors
	drop table #errorsSeen_now
	drop table #errorsSeen_then
end
