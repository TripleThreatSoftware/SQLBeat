create procedure pr_monitorPageLifeExpectancy
as
begin

	declare @nUkeyCounter int
	declare @nUkeyObject int

	set @nUkeyCounter = (select top 1 ukey from dm_performanceCounters where counterName = 'Page life expectancy')
	set @nUkeyObject = (select top 1 ukey from dm_performanceObjects where objectName = 'SQLServer:Buffer Manager')

	insert into notificationLog_stage (serverName, severity, subject, message)
	select serverName, 2 as severity,
		'Average page life expectancy is ' + convert(varchar(20), pageLifeExpectancy_avg) + ' @ ' + convert(varchar(20), b.ymd, 120) as subject,
		'Over ' + convert(varchar(20), numReadings) + ' readings starting at ' + convert(varchar(20), b.ymd, 120) + ' average page life expectancy was ' + convert(varchar(20), pageLifeExpectancy_avg) + '.'

		from dm_servers a
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
				group by ukey_server
				having count(*) >= 2
			) b on a.ukey = b.ukey_server
				and pageLifeExpectancy_avg < a.pageLifeExpectancyAlertThreshold
		join dm_serverGroups c on a.ukey_group = c.ukey
			and c.isProduction = 1
		order by ymd
end
GO
