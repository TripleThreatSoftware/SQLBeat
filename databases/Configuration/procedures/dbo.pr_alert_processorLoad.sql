SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_alert_processorLoad]
as
begin

	select
		a.ymd,
		c.serverName,
		a.processorName as instance,
		a.processorName as processor,
		a.processorLoad

		into #loadReadings

		from processorLoadLog a (nolock)
		join notification..dm_servers c (nolock) on a.ukey_server = c.ukey
		where a.ymd > dateAdd(hour, -1, getDate())

	-- cpu load
	select serverName, processor,
		max(ymd) as latestReading,
		convert(int, 0) as latestValue,
		min(processorLoad) as minValue,
		max(processorLoad) as maxValue,
		avg(processorLoad) as avgValue,
		count(*) as numReadings

		into #loadSummary
		from #loadReadings a
		group by serverName, processor
		having count(*) >= 3
		order by serverName, processor

	update #loadSummary
		set latestValue = b.processorLoad
		from #loadSummary a
		join #loadReadings b on a.serverName = b.serverName
			and a.latestReading = b.ymd
			and a.processor = b.processor

	declare @cThisServer varchar(200)
	declare @cThisSubject varchar(500)
	declare @cThisMessage varchar(8000)
	declare @dLatestReading dateTime
	declare @nAverageValue decimal(10,2)
	declare @nSeverity int
	declare @nNumAlerts int

	set @cThisServer = ''

	while exists (
		select top 1 serverName
			from #loadSummary
			where serverName > @cThisServer
				 and serverName in (
					select serverName from #loadReadings group by serverName having max(processorLoad) > 50 and avg(processorLoad) > 30
					)
		)
	begin
		set @nSeverity = 1

		select top 1
			@cThisServer = serverName,
				@dLatestReading = latestReading
			from #loadSummary
			where serverName > @cThisServer
				 and serverName in (
					select serverName from #loadReadings group by serverName having max(processorLoad) > 50 and avg(processorLoad) > 30
					)
			order by serverName

		set @nAverageValue = (select avg(avgValue) from #loadSummary where serverName = @cThisServer)

		set @cThisSubject = 'CPU load at ' + left(right(convert(varchar(20), @dLatestReading, 120), 8), 5) + ' averaging ' + convert(varchar(20), @nAverageValue) + '.'

		set @cThisMessage = 'CPU load for 1 hour up to ' + convert(varchar(19), @dLatestReading, 120) + ' has triggered an alert for ' + @cThisServer + char(13) + char(13) +
			'<table border="0" cellspacing="0" cellpadding="0" width="100%" style="font-family:Courier; font-size: x-small;">' +
			'<tr>' +
			'<th>Processor</th>' +
			'<th>Latest Reading</th>' +
			'<th>Now</th>' +
			'<th>Min</th>' +
			'<th>Max</th>' +
			'<th>Avg</th>' +
			'<th>#</th></tr>'

		select @cThisMessage = @cThisMessage +
			'<tr>' +
			'<td>' + processor + '</td>' +
			'<td align="right">' + convert(varchar(19), latestReading, 120) + '</td>' +
			'<td align="right">' + convert(varchar(3), latestValue) + '</td>' +
			'<td align="right">' + convert(varchar(3), minValue) + '</td>' +
			'<td align="right">' + convert(varchar(3), maxValue) + '</td>' +
			'<td align="right">' + convert(varchar(3), avgValue) + '</td>' +
			'<td align="right">' + convert(varchar(3), numReadings) + '</td></tr>'
			from #loadSummary
			where serverName = @cThisServer
			order by processor

		set @cThisMessage = @cThisMessage + '</table>'

		-- number of CPU alerts in the last hour
		set @nNumAlerts = (select count(*) from notification..notificationLog (nolock) where serverName = @cThisServer and subject like '%cpu load%' and ymd >= dateAdd(hour, -1, getDate()))

		set @nSeverity = case
			when @nNumAlerts = 0 then 2
			when @nNumAlerts = 1 then 1
			else 1 end


--		print @cThisSubject
--		print @cThisMessage

		insert into notification..notificationLog_Stage (serverName, subject, message, severity) values (@cThisServer, @cThisSubject, @cThisMessage, @nSeverity)

		delete from #loadSummary where serverName = @cThisServer
	end

	drop table #loadSummary
	drop table #loadReadings

end
