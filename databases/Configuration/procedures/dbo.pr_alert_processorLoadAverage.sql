USE [Configuration]
GO
/****** Object:  StoredProcedure [dbo].[pr_alert_processorLoadAverage]    Script Date: 8/30/2018 4:52:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_alert_processorLoadAverage]
as
begin

	declare @dToday dateTime
	set @dToday = convert(varchar(10), isnull(@dToday, dateAdd(day, -1, getDate())), 120)

--	set @dToday = '2018-08-24'

	create table #readings (ymd dateTime, ukey_server int, instance varchar(100), processor varchar(200), processorLoad int)

	insert into #readings (ymd, instance, ukey_server, processor, processorLoad)
	select ymd, processorName, ukey_server, processorName, processorLoad
		from processorLoadLog (nolock)
		where ymd >= dateAdd(month, -1, @dToday)

	select ukey_server, -- instance, processor,
		avg(convert(decimal(10,2), processorLoad)) as processorLoad,
		count(*) as numReadings,
		count(distinct convert(varchar(10), ymd, 120)) as numDays
		into #averages
		from #readings
		group by ukey_server --, instance, processor

	insert into notification.dbo.notificationLog_stage (serverName, subject, message, severity)
	select
		c.serverName,
		'CPU load increased by ' + convert(varchar(20), convert(decimal(10,2), (a.avgValue - b.processorLoad))) + ' percentage points on ' + convert(varchar(20), a.ymd) + '.' as subject,
		'Average CPU load on ' + c.serverName + ' ' +
			'over ' + convert(varchar(20), b.numReadings) + ' readings ' +
			'on the last ' + convert(varchar(20), b.numDays) + ' ' + dateName(weekDay, @dToday) + 's ' +
			'has been ' + convert(varchar(20), convert(decimal(10,2), b.processorLoad)) + '%. ' + char(13) +
			'Yesterday, ' + convert(varchar(20), a.ymd) + ', ' +
			convert(varchar(20), a.numReadings) + ' readings ' +
			'indicated an average CPU load of ' + convert(varchar(20), convert(decimal(10,2), a.avgValue)) + '%. ' +
			'This is an increase of ' + convert(varchar(20), convert(decimal(10,2), (a.avgValue - b.processorLoad))) + ' percentage points, ' +
			'or ' + convert(varchar(20), convert(decimal(10,2), ((a.avgValue - b.processorLoad) / b.processorLoad) * 100)) + '% net.' as message,
		case when abs(a.avgValue - b.processorLoad) > 20 then 1 else 2 end as severity
		from (
			-- yesterday
			select
				convert(varchar(10), a.ymd, 120) as ymd,
				ukey_server, --processor, instance,
				max(processorLoad) as maxValue,
				avg(convert(decimal(10,2), processorLoad)) as avgValue,
				count(*) as numReadings

				from #readings a
				where ymd >= @dToday
					and ymd < dateAdd(day, 1, @dToday)

				group by convert(varchar(10), a.ymd, 120), ukey_server --, processor, instance
			) a
		join #averages b on a.ukey_server = b.ukey_server
		join notification.dbo.dm_servers c on a.ukey_server = c.ukey
		join notification.dbo.dm_serverGroups d on c.ukey_group = d.ukey
			and d.isProduction = 1
		where convert(decimal(10,2), (a.avgValue - b.processorLoad)) >= 10
		order by c.serverName, a.ymd --, a.processor, a.instance

	drop table #readings
	drop table #averages
end
