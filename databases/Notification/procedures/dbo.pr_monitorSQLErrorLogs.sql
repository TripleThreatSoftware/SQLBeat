SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--select top 10 * from notificationLog_Stage
-- truncate table notificationLog_Stage

ALTER procedure [dbo].[pr_monitorSQLErrorLogs]
as
begin
	declare @dMinDate dateTime
	set @dMinDate = dateAdd(hour, -2, getDate())
--	set @dMinDate = dateAdd(minute, 15 * datePart(minute, getDate()) / 15, convert(varchar(14), getDate(), 120) + '00.000')

	create table #errorsFound (ymd dateTime, serverName varchar(200), processInfo varchar(500), logMessage varchar(8000),
		ukey int, isLoginFailure bit default 0, isDeadlock bit default 0)

	insert into #errorsFound (ymd, serverName, processInfo, logMessage, ukey)
	select
		ymd, serverName, processInfo, convert(varchar(8000), logMessage) as logMessage, ukey
		from sqlErrorLog (nolock)
		where ymd >= @dMinDate
			and (
				logMessage like '%deadlock%'
				or logMessage like '%login failed%'
				or (logMessage like '%error%' and logMessage not like '%0 errors%' and logMessage not like '%without errors%')
				or logMessage like '%a significant part%'
				or logMessage like '%terminating%'
				or logMessage like '%shutdown%'
				or logMessage like '%upgrade%'
				or logMessage like '%local node that is running the server%'
				or logMessage like '%execution of%'
				or processInfo = 'Server'
				)
			and logMessage not like '%reinitialized%'
			and logMessage not like '%logging sql server messages%'

	insert into #errorsFound (ymd, serverName, processInfo, logMessage, ukey)
	select distinct a.ymd, a.serverName, a.processInfo, a.logMessage, a.ukey
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

	select a.*,
		'Login failure for user "' + loginName + '" from "' + clientAddress + '" at ' + convert(varchar(20), ymd, 120) + '.' as subject,
		'Login failure for user "' + loginName + '" from "' + clientAddress + '" at ' + convert(varchar(20), ymd, 120) + '.' as message,
		identity(int) as ukey
		into #loginFailures
		from (
			select
				serverName,
				ymd,
				replace(substring(logMessage, charindex('client:', logMessage) + 8, 8000), ']', '') as clientAddress,
				substring(logMessage, charindex('for user', logMessage) + 10, charindex('.', logMessage) - charindex('for user', logMessage) - 11) as loginName,
				logMessage
				from #errorsFound
				where isLoginFailure = 1
					and charindex('client:', logMessage) > 0
					and logMessage not like '%sspi%'
			) a

	-- only report on failures since the last attempt
	delete #loginFailures
		from #loginFailures a
		join (
			select serverName, max(ymd) as ymd
				from notificationLog (nolock)
				where subject like '%login failure%'
					and ymd >= dateAdd(hour, -12, getDate())
				group by serverName
			) b on a.serverName = b.serverName
				and a.ymd <= b.ymd

	declare @nThisUkey int
	declare @cServerName varchar(100)
	declare @dYMDBegin dateTime
	declare @dYMDEnd dateTime
	declare @cMessage varchar(8000)
	declare @cLoginName varchar(200)
	declare @cClientAddress varchar(200)
	declare @cProcessInfo varchar(200)
	declare @nNumFailures int
	declare @cSubject varchar(8000)

	set @cServerName = ''
	while exists (select top 1 serverName from #loginFailures where serverName > @cServerName)
	begin
		select top 1
			@cServerName = serverName,
			@nNumFailures = count(*),
			@dYMDBegin = max(ymd)
			from #loginFailures
			where serverName > @cServerName
			group by serverName
			order by serverName

		-- if we've got lots of failures for a long time, increase the priority
		if (
			select top 1 b.isProduction
				from dm_servers a (nolock)
				join dm_serverGroups b (nolock) on a.ukey_group = b.ukey
				where a.serverName = @cServerName
			) = 1
			and (
				@nNumFailures >= 5
				or (
					(
						select count(*)
							from notificationLog (nolock)
							where serverName = @cServerName
								and subject like '%login failure%'
								and ymd >= dateAdd(hour, -1, getDate())
						) >= 4
					)
				)
		begin
			set @cSubject = 'Login failure for ' + convert(varchar(20), @nNumFailures) + ' users at ' + convert(varchar(20), @dYMDBegin, 120) + '.'
			set @cMessage = ''

			select @cMessage = @cMessage + '<br>' + [message]
				from #loginFailures
				where serverName = @cServerName
				order by ymd

			insert into notificationLog_stage (serverName, subject, message, severity) values (@cServerName, @cSubject, @cMessage, 1)

			delete from #loginFailures where serverName = @cServerName
		end
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
			from #errorsFound
			where serverName = @cServerName
				and ymd = @dYMDBegin
				and processInfo = @cProcessInfo
			order by ymd

		update #deadlocks
			set message = message + char(13) + @cMessage
			where ukey = @nThisUkey
	end


	delete #loginFailures
		from #loginFailures a
		join dm_servers b on a.serverName = b.serverName
		left outer join dm_serverGroups c on b.ukey_group = c.ukey
			and c.isProduction = 1
		where c.ukey is null

	select distinct serverName, processInfo, ymd, identity(int) as ukey
		into #otherErrors
		from #errorsFound
		where isDeadlock = 0 and isLoginFailure = 0

	set @nThisUkey = 0

	while exists (select top 1 ukey from #otherErrors where ukey > @nThisUkey)
	begin
		select top 1
			@cServerName = serverName,
			@dYMDBegin = ymd,
			@nThisUkey = ukey,
			@cSubject = 'SQL Error from [' + processInfo + '] at ' + right(convert(varchar(20), ymd, 120), 8),
			@cProcessInfo = processInfo
			from #otherErrors
			where ukey > @nThisUkey
			order by ukey

		set @cMessage = ''

		select @cMessage = @cMessage + logMessage + '<br>'
			from (
				select top 500 logMessage
					from #errorsFound
					where serverName = @cServerName
						and ymd = @dYMDBegin
						and processInfo = @cProcessInfo
					order by ukey
				) a

		insert into notificationLog_stage (ymd, serverName, severity, subject, message) values (@dYMDBegin, @cServerName, 2, @cSubject, @cMessage)
	end

	insert into notificationLog_stage (ymd, serverName, severity, subject, message)
	select distinct ymd, serverName, 2, subject, message from #loginFailures
	union
	select distinct ymd, serverName, 1, subject, message from #deadlocks


	drop table #errorsFound
	drop table #loginFailures
	drop table #deadlocks
	drop table #otherErrors
end
