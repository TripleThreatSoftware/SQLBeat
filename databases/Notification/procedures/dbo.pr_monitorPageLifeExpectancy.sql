/****** Object:  StoredProcedure [dbo].[pr_monitorPageLifeExpectancy]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_monitorPageLifeExpectancy]
as
begin

	declare @nUkeyCounter int
	declare @nUkeyObject int
	declare @nRunStamp bigint

	set @nRunStamp = (select dbo.fn_returnRunStamp(dateAdd(day, -1, getDate())))
	set @nUkeyCounter = (select top 1 ukey from dm_performanceCounters (nolock) where counterName = 'Page life expectancy')
	set @nUkeyObject = (select top 1 ukey from dm_performanceObjects (nolock) where objectName = 'SQLServer:Buffer Manager')

	insert into notificationLog_stage (serverName, severity, subject, message)
	select serverName, 2 as severity,
		'Average page life expectancy is ' + convert(varchar(20), pageLifeExpectancy_avg) + ' @ ' + convert(varchar(20), b.ymd, 120) as subject,
		'Over ' + convert(varchar(20), numReadings) + ' readings starting at ' + convert(varchar(20), b.ymd, 120) + ' average page life expectancy was ' + convert(varchar(20), pageLifeExpectancy_avg) + '.'

		from dm_servers a (nolock)
		join (
			select
				ukey_server,
				min(ymd) as ymd,
				count(*) as numReadings,
				min(counterValue) as pageLifeExpectancy_min,
				avg(counterValue) as pageLifeExpectancy_avg
				from performanceLog a (nolock)
				where ukey_counter = @nUkeyCounter
					and ukey_object = @nUkeyObject
					and ymd >= dateAdd(minute, -20, getDate())
					and runstamp >= @nRunStamp
				group by ukey_server
				having count(*) >= 2
			) b on a.ukey = b.ukey_server
				and pageLifeExpectancy_avg < a.pageLifeExpectancyAlertThreshold
		join dm_serverGroups c (nolock) on a.ukey_group = c.ukey
			and c.isProduction = 1
		order by ymd
end
GO
