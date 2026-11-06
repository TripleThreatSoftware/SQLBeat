/****** Object:  StoredProcedure [dbo].[pr_alert_fileErrorRate]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_alert_fileErrorRate]
as
begin
	declare @dToday dateTime
	set @dToday = convert(varchar(10), dateAdd(day, -1, getDate()), 120)

	select
		a.friendlyName, d.uriStem, a.hour, a.requestStatus,
		a.observed, c.expected,
		convert(decimal(10,2), 100 *
			case when isnull(c.expected, 0) = 0
				then 100
				else convert(decimal(20,4), a.observed - c.expected) / convert(decimal(20,4), c.expected) end) as delta,
		isnull(b.numRequests, 0) as successfulRequests
		into #results
		from (
			select
				c.friendlyName, a.ukey_uriStem, a.hour, a.requestStatus,
				sum(a.numRequests) as observed
				from mart_page_byHour a (nolock)
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and (c.friendlyName like 'PRO%' or c.friendlyName like 'UAT%' or c.friendlyName like 'FUN%')
				where (a.requestStatus like '4%' or a.requestStatus like '5%')
					and a.ymd = @dToday
				group by c.friendlyName, a.ukey_uriStem, a.hour, a.requestStatus
			) a
		left outer join (
			select
				c.friendlyName, a.ukey_uriStem, a.hour, a.requestStatus,
				convert(int, convert(decimal(10,2), sum(a.numRequests)) / convert(decimal(10,2), count(distinct a.ymd))) as expected
				from mart_page_byHour a (nolock)
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and (c.friendlyName like 'PRO%' or c.friendlyName like 'UAT%' or c.friendlyName like 'FUN%')
				where (a.requestStatus like '4%' or a.requestStatus like '5%')
					and (
						a.ymd = dateAdd(day, -7, @dToday)
						or a.ymd = dateAdd(day, -14, @dToday)
						or a.ymd = dateAdd(day, -21, @dToday)
						)
				group by c.friendlyName, a.ukey_uriStem, a.hour, a.requestStatus
			) c on a.friendlyName = c.friendlyName
				and a.ukey_uriStem = c.ukey_uriStem
				and a.hour = c.hour
		left outer join (
			select c.friendlyName, a.ukey_uriStem, a.[hour], sum(a.numRequests) as numRequests
				from mart_page_byHour a (nolock)
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and (c.friendlyName like 'PRO%' or c.friendlyName like 'UAT%' or c.friendlyName like 'FUN%')
				where not (a.requestStatus like '4%' or a.requestStatus like '5%')
					and a.ymd = @dToday
				group by c.friendlyName, a.ukey_uriStem, a.ymd, a.[hour]
			) b on a.friendlyName = b.friendlyName
				and a.ukey_uriStem = b.ukey_uriStem
				and a.hour = b.hour
		join dm_uriStem d (nolock) on a.ukey_uriStem = d.ukey
		where a.observed + isnull(c.expected, 0) >= 50
			and convert(decimal(10,2), 100 * case when isnull(c.expected, 0) = 0 then 100 else convert(decimal(20,4), a.observed - c.expected) / convert(decimal(20,4), c.expected) end) > 25
		order by a.friendlyName, d.uriStem, a.hour

	declare @cFriendlyName varchar(200)
	declare @cMessage varchar(8000)
	declare @cSubject varchar(500)
	declare @dPreviousDay dateTime
	set @cFriendlyName = ''

	while exists (select top 1 friendlyName from #results where friendlyName > @cFriendlyName)
	begin
		select top 1
			@cFriendlyName = friendlyName,
			@cSubject = 'HTTP error rate alert for "' + friendlyName + '" on ' + convert(varchar(10), @dToday, 120)
			from #results
			where friendlyName > @cFriendlyName
			order by friendlyName

		set @cMessage = 'Errors for "' + @cFriendlyName + '" from ' + convert(varchar(10), @dToday, 120) + ' were compared to the previous three ' + dateName(weekday, @dToday) + 's : ' + char(13) + char(13) +
			left('URI' + space(20), 20) + space(1) +
			left('Return' + space(7), 7) + space(1) +
			left('Hour' + space(4), 4) + space(1) +
			left('Observed' + space(9), 9) + space(1) +
			left('Expected' + space(9), 9) + space(1) +
			left('Delta' + space(8), 8) + space(1) +
			left('Successful' + space(10), 10) + char(13) +
			replicate('=', 20) + space(1) +
			replicate('=', 7) + space(1) +
			replicate('=', 4) + space(1) +
			replicate('=', 9) + space(1) +
			replicate('=', 9) + space(1) +
			replicate('=', 8) + space(1) +
			replicate('=', 10) + char(13)

		select @cMessage = @cMessage +
			left(uriStem + space(20), 20) + space(1) +
			left(convert(varchar(20), requestStatus) + space(7), 7) + space(1) +
			left(convert(varchar(20), [hour]) + space(4), 4) + space(1) +
			right(space(9) + convert(varchar(20), observed), 9) + space(1) +
			right(space(9) + convert(varchar(20), expected), 9) + space(1) +
			right(space(8) + convert(varchar(20), delta) + '%', 8) + space(1) +
			right(space(10) + convert(varchar(20), successfulRequests), 10) + char(13)

			from #results
			where friendlyName = @cFriendlyName
			order by uriStem, [hour]

		insert into notification..notificationLog_stage (serverName, subject, message, severity) values (@cFriendlyName, @cSubject, @cMessage, 2)

		print @cSubject
		print @cMessage

	end

	drop table #results
end
GO
