SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop table dm_performanceStatThresholds
--go
--create table dm_performanceStatThresholds (ukey int identity, ymd dateTime default getDate(),
--	ukey_server int, ukey_object int, ukey_counter int, instanceName varchar(500), minValue decimal(20,4), maxValue decimal(20,4))
--go


ALTER procedure [dbo].[pr_monitorSQLStatistics]
as
begin
	declare @cServerName varchar(200)
	declare @cSubject varchar(500)
	declare @cMessage varchar(8000)
	declare @nRunstamp bigint
	declare @nUkeyServer int
	declare @dRunstamp dateTime

	select ukey_server, max(runstamp) as runstamp
		into #latestRun
		from performanceLog (nolock)
		group by ukey_server

	select a.ukey_server, e.serverName, d.objectName, c.counterName, a.instanceName, a.counterValue, b.minValue, b.maxValue
		into #results

		from performanceLog a (nolock)
		join dm_performanceStatThresholds b (nolock) on (a.ukey_server = b.ukey_server or isnull(b.ukey_server, 0) = 0)
			and (a.ukey_object = b.ukey_object or isnull(b.ukey_object, 0) = 0)
			and (a.ukey_counter = b.ukey_counter or isnull(b.ukey_counter, 0) = 0)
			and (a.instanceName = b.instanceName or isnull(b.instanceName, '') = '')
			and (
				(a.counterValue <= b.minValue and b.minValue is not null)
				or (a.counterValue >= b.maxValue and b.maxValue is not null)
				)
		join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
		join dm_performanceObjects d (nolock) on a.ukey_object = d.ukey
		join dm_servers e (nolock) on a.ukey_server = e.ukey
			and e.statisticsCheck = 1
		join #latestRun f on a.runStamp = f.runStamp
			and a.ukey_server = f.ukey_server
		where isnumeric(a.counterValue) = 1
--			and a.ymd >= dateAdd(minute, -10, getDate())

	set @cServerName = ''
	while exists (select top 1 serverName from #results where serverName > @cServerName)
	begin
		select top 1
			@cServerName = serverName,
			@nUkeyServer = ukey_server
			from #results
			where serverName > @cServerName
			order by serverName

		set @nRunstamp = (select top 1 runstamp from #latestRun where ukey_server = @nUkeyServer)
		set @dRunstamp = (select dbo.fn_runstampToString(@nRunstamp))

		set @cMessage = '<table width="100%" border="1" cellpadding="1" cellspacing="0"><tr><th>Object</th><th>Counter</th><th>Instance</th><th>Reading</th><th>Min</th><th>Max</th></tr>'
		set @cSubject = 'SQL statistics outside of thresholds at ' + dbo.fn_runstampToString(@nRunstamp)

		select @cMessage = @cMessage +
			'<tr>' +
				'<td>' + rtrim(ltrim(objectName)) + '</td>' +
				'<td>' + rtrim(ltrim(counterName)) + '</td>' +
				'<td>' + rtrim(ltrim(instanceName)) + '</td>' +
				'<td align="right">' + convert(varchar(100), counterValue) + '</td>' +
				'<td align="right">' + isnull(convert(varchar(100), minValue), 'N/A') + '</td>' +
				'<td align="right">' + isnull(convert(varchar(100), case when maxValue > 100 then convert(int, maxValue) else maxValue end), 'N/A') + '</td>' +
			'</tr>'
			from #results
			where serverName = @cServerName
			order by objectName, counterName, instanceName

		set @cMessage = @cMessage + '</table>'

		insert into notificationLog_stage (serverName, subject, message, ymd, severity) values (@cServerName, @cSubject, @cMessage, @dRunstamp, 1)
	end

	drop table #latestRun
	drop table #results
end
