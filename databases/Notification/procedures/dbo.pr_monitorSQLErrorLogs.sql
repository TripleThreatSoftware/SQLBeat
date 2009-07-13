ALTER procedure [dbo].[pr_monitorSQLErrorLogs]
as
begin
	declare @dMinDate dateTime
	set @dMinDate = dateAdd(minute, 15 * datePart(minute, getDate()) / 15, convert(varchar(14), getDate(), 120) + '00.000')

	create table #errorsFound (ymd dateTime, serverName varchar(200), processInfo varchar(500), logMessage varchar(8000),
		ukey int, isLoginFailure bit default 0, isDeadlock bit default 0)

	insert into #errorsFound (ymd, serverName, processInfo, logMessage, ukey)
	select
		ymd, serverName, processInfo, convert(varchar(8000), logMessage) as logMessage, ukey
		from sqlErrorLog (nolock)
		where ymd >= dateAdd(day, -2, getDate())
			and (
				logMessage like '%deadlock%'
				or logMessage like '%login failed%'
				or (logMessage like '%error%' and logMessage not like '%0 errors%' and logMessage not like '%without errors%')
				or logMessage like '%a significant part%'
				)

	insert into #errorsFound (ymd, serverName, processInfo, logMessage, ukey)
	select a.ymd, a.serverName, a.processInfo, a.logMessage, a.ukey
		from sqlErrorLog a (nolock)
		join #errorsFound b on a.ymd = b.ymd
			and a.processInfo = b.processInfo
			and a.serverName = b.serverName
			and a.ukey >= b.ukey - 15
			and a.ukey <= b.ukey + 15
		left outer join #errorsFound c on a.ukey = c.ukey
		where c.ukey is null

	update #errorsFound
		set isLoginFailure = 1
		where processInfo = 'Logon'

	update #errorsFound
		set isDeadlock = 1
		where logMessage like '%deadlock%'

	select
		serverName,
		ymd,
		processInfo,
		'Deadlock for ' + processInfo + ' at ' + convert(varchar(20), ymd, 120) + '.' as subject,
		convert(varchar(8000), '') as message,
		identity(int) as ukey
		into #deadlocks
		from #errorsFound
		where isDeadlock = 1

	select
		serverName,
		ymd,
		replace(substring(logMessage, charindex('client:', logMessage) + 8, 8000), ']', '') as clientAddress,
		substring(logMessage, charindex('for user', logMessage) + 10, charindex('.', logMessage) - charindex('for user', logMessage) - 11) as loginName,
		logMessage
		into #loginFailures
		from #errorsFound
		where isLoginFailure = 1
			and charindex('client:', logMessage) > 0
			and logMessage not like '%sspi%'

	select
		serverName,
		min(ymd) as ymd_min,
		max(ymd) as ymd_max,
		clientAddress,
		'Login failure alert for host "' + clientAddress + '" at ' + convert(varchar(20), max(ymd), 120) + '.' as subject,
		'Between ' + convert(varchar(20), min(ymd), 120) + ' and ' + convert(varchar(20), max(ymd), 120) + ' there have been ' + convert(varchar(20), count(*)) + ' failed login attempts from host "' + clientAddress + '".' as message,
		identity(int) as ukey
		into #loginAddressFailures
		from #loginFailures
		where ymd < @dMinDate
			and clientAddress <> ''
		group by serverName, clientAddress, convert(varchar(10), ymd, 120), datePart(hour, ymd), datePart(minute, ymd) / 15

	select
		serverName,
		min(ymd) as ymd_min,
		max(ymd) as ymd_max,
		loginName,
		'Login failure alert for user "' + loginName + '" at ' + convert(varchar(20), max(ymd), 120) + '.' as subject,
		'Between ' + convert(varchar(20), min(ymd), 120) + ' and ' + convert(varchar(20), max(ymd), 120) + ' there have been ' + convert(varchar(20), count(*)) + ' failed login attempts for login "' + loginName + '".' as message,
		identity(int) as ukey
		into #loginNameFailures
		from #loginFailures
		where ymd < @dMinDate
			and loginName <> ''
		group by serverName, loginName, convert(varchar(10), ymd, 120), datePart(hour, ymd), datePart(minute, ymd) / 15


	declare @nThisUkey int
	declare @cServerName varchar(100)
	declare @dYMDBegin dateTime
	declare @dYMDEnd dateTime
	declare @cMessage varchar(8000)
	declare @cLoginName varchar(200)
	declare @cClientAddress varchar(200)
	declare @cProcessInfo varchar(200)
	set @nThisUkey = 0

	while exists (select top 1 ukey from #loginAddressFailures where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@cServerName = serverName,
			@dYMDBegin = ymd_min,
			@dYMDEnd = ymd_max,
			@cClientAddress = clientAddress
			from #loginAddressFailures
			where ukey > @nThisUkey
			order by ukey

		set @cMessage = ''

		select @cMessage = @cMessage + logMessage + char(13)
			from #loginFailures
			where serverName = @cServerName
				and ymd >= @dYMDBegin
				and ymd <= @dYMDEnd
				and clientAddress = @cClientAddress
			order by ymd

		update #loginAddressFailures
			set message = message + char(13) + @cMessage
			where ukey = @nThisUkey
	end

	set @nThisUkey = 0

	while exists (select top 1 ukey from #loginNameFailures where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@cServerName = serverName,
			@dYMDBegin = ymd_min,
			@dYMDEnd = ymd_max,
			@cLoginName = loginName
			from #loginNameFailures
			where ukey > @nThisUkey
			order by ukey

		set @cMessage = ''

		select @cMessage = @cMessage + logMessage + char(13)
			from #loginFailures
			where serverName = @cServerName
				and ymd >= @dYMDBegin
				and ymd <= @dYMDEnd
				and loginName = @cLoginName
			order by ymd

		update #loginNameFailures
			set message = message + char(13) + @cMessage
			where ukey = @nThisUkey
	end

	set @nThisUkey = 0

	while exists (select top 1 ukey from #deadlocks where ukey > @nThisUkey)
	begin
		select top 1
			@nThisUkey = ukey,
			@cServerName = serverName,
			@dYMDBegin = ymd,
			@cProcessInfo = processInfo
			from #deadlocks
			where ukey > @nThisUkey
			order by ukey

		set @cMessage = ''

		select @cMessage = @cMessage + logMessage + char(13)
			from #deadlocks
			where serverName = @cServerName
				and ymd = @dYMDBegin
				and processInfo = @cProcessInfo
			order by ymd

		update #deadlocks
			set message = message + char(13) + @cMessage
			where ukey = @nThisUkey
	end


	delete #loginAddressFailures
		from #loginAddressFailures a
		join dm_servers b on a.serverName = b.serverName
		left outer join dm_serverGroups c on b.ukey_group = c.ukey
			and c.isProduction = 1
		where c.ukey is null

	delete #loginNameFailures
		from #loginNameFailures a
		join dm_servers b on a.serverName = b.serverName
		left outer join dm_serverGroups c on b.ukey_group = c.ukey
			and c.isProduction = 1
		where c.ukey is null


	insert into notificationLog_stage (ymd, serverName, severity, subject, message)
	select distinct ymd_max, serverName, 1, subject, message from #loginAddressFailures
	union
	select distinct ymd_max, serverName, 1, subject, message from #loginNameFailures
	union
	select distinct ymd, serverName, 1, subject, message from #deadlocks
	union
	select
		ymd, serverName, 1, left(logMessage, 100) as subject, convert(varchar(8000), logMessage) as message
		from sqlErrorLog (nolock)
		where ymd >= dateAdd(day, -2, getDate())
			and (
				logMessage like '%a significant part%'
				)

	drop table #errorsFound
	drop table #loginFailures
	drop table #loginAddressFailures
	drop table #loginNameFailures
	drop table #deadlocks
end
