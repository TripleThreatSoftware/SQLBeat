-- select top 100 * from pingResults order by ymd desc
-- exec pr_pingServer 'appweb01'
-- update pingResults set sqlPingResults = pingResults where sqlPingResults is null
-- alter table pingResults drop column pingResults
CREATE           procedure [dbo].[pr_pingServer] (@cServerName varchar(100))
as
begin
	declare @cServerNamePart varchar(100)
	declare @cInstanceNamePart varchar(100)
	declare @cCommandline varchar(200)
	declare @cFriendlyName varchar(200)
	declare @nTimesUnavailable int
	declare @cThisSubject varchar(300)
	declare @cThisMessage varchar(2000)
	declare @bPingServer bit
	declare @bIsBusinessHours bit
	declare @nOffHoursPriority int

	declare @cRouterMessage varchar(2000)
	declare @cServerMessage varchar(2000)
	declare @cSQLMessage varchar(2000)

	declare @bIsRouterPingable bit
	declare @bIsServerPingable bit
	declare @bIsSQLPingable bit
	declare @bIsEnabled bit

	declare @bServiceCheck bit

	set @bPingServer = 1

	set @bIsRouterPingable = 1
	set @bIsServerPingable = 1
	set @bIsSQLPingable = 1
	set @bIsBusinessHours = (select dbo.fn_isBusinessHours())

	set @cRouterMessage = ''
	set @cServerMessage = ''
	set @cSQLMessage = ''

	create table #sqlPing (results varchar(500))

	--*********************************************************************************************************
	-- Get the basic demographics together
	--*********************************************************************************************************

	select top 1
		@cFriendlyName = isnull(friendlyName, @cServerName),
		@bPingServer = pingCheck,
		@nOffHoursPriority = offHoursPriority,
		@bServiceCheck = serviceCheck,
		@bIsEnabled = isEnabled
		from dm_servers (nolock)
		where serverName = @cServerName
--			and isEnabled = 1

--	if isnull(@bPingServer, 1) = 0
--		return 1

	--*********************************************************************************************************
	-- Sort out the proper naming of the server
	--*********************************************************************************************************

	set @cServerNamePart = @cServerName
	set @cInstanceNamePart = ''

	if charindex('\', @cServerName) > 0
	begin
		set @cServerNamePart = left(@cServerName, charindex('\', @cServerName) - 1)
		set @cInstanceNamePart = right(@cServerName, len(@cServerName) - charindex('\', @cServerName))
	end

--	--*********************************************************************************************************
--	-- if it's a store, ping the router first
--	--*********************************************************************************************************
--	if @bIsStoreMachine = 1 and right(@cServerName, 2) = '.3'
--	begin
--		truncate table #sqlPing
--
--		set @cCommandline = 'ping ' + left(@cServerNamePart, len(@cServerNamePart) - 2) + '.1'
--
--		insert into #sqlPing
--		exec master..xp_cmdshell @cCommandline
--
--		set @cRouterMessage = ''
--
--		select @cRouterMessage = @cRouterMessage + isnull(results, '') + char(13) --+ case when results like '%reply from%' then char(13) else '' end
--			from #sqlPing
--
--		if (@cRouterMessage not like '%received = 4%' and @cRouterMessage not like '%received = 3%') or @cRouterMessage like '%ttl expired in transit%'
--			set @bIsRouterPingable = 0
--		else
--			set @bIsRouterPingable = 1
--	end

	--*********************************************************************************************************
	-- Now, if that worked, try and hit the server
	--*********************************************************************************************************
	if @bIsRouterPingable = 1
	begin
		truncate table #sqlPing

		set @cCommandline = 'ping ' + @cServerNamePart

		insert into #sqlPing
		exec master..xp_cmdshell @cCommandline

		set @cServerMessage = ''

		select @cServerMessage = @cServerMessage + isnull(results, '') + char(13) --+ case when results like '%reply from%' then char(13) else '' end
			from #sqlPing

		if (@cServerMessage not like '%received = 4%' and @cServerMessage not like '%received = 3%' and @cServerMessage not like '%received = 2%') or @cServerMessage like '%ttl expired in transit%'
			set @bIsServerPingable = 0
		else
			set @bIsServerPingable = 1
	end
	else
	begin
		set @bIsServerPingable = 0
		set @bIsSQLPingable = 0
	end

	--*********************************************************************************************************
	-- And boy howdy, if that worked, hit the SQL service
	--*********************************************************************************************************
	if @bIsServerPingable = 1 and @bServiceCheck = 1
	begin
		truncate table #sqlPing

		declare @cSQLPingLocation varchar(200)
		set @cSQLPingLocation = (select settingValue from dm_settings where settingName = 'SQLPing Location')

		if isnull(@cSQLPingLocation, '') <> ''
		begin

			set @cCommandline = @cSQLPingLocation + '\sqlping ' + @cServerNamePart

			insert into #sqlPing
			exec master..xp_cmdshell @cCommandline

			if (select count(*) from #sqlPing where results = 'ServerName:' + @cServerNamePart or results like 'ServerName:' + @cFriendlyName + '%') > 0
			begin
				set @bIsSQLPingable = 1
				if (@cInstanceNamePart <> ''
					and (select count(*) from #sqlPing where results = 'InstanceName:' + @cInstanceNamePart) = 0)
					set @bIsSQLPingable = 0
			end
			else
			begin
				-- try a second time
				truncate table #sqlPing

				insert into #sqlPing
				exec master..xp_cmdshell @cCommandline

				if (select count(*) from #sqlPing where results = 'ServerName:' + @cServerNamePart or results like 'ServerName:' + @cFriendlyName + '%') > 0
				begin
					set @bIsSQLPingable = 1
					if (@cInstanceNamePart <> ''
						and (select count(*) from #sqlPing where results = 'InstanceName:' + @cInstanceNamePart) = 0)
						set @bIsSQLPingable = 0
				end
			end

			select @cSQLMessage = @cSQLMessage + isnull(results, '') + char(13)
				from #sqlPing
		end
	end

	update dm_servers with (rowlock)
		set isServerPingable = @bIsServerPingable,
			isSQLServiceRunning = @bIsSQLPingable,
			lastPingCheck = getDate()
--			,isEnabled = case when @bIsServerPingable = 1 then 1 else isEnabled end
		where serverName = @cServerName

	insert into pingLog (serverName, friendlyName,
		isServerPingable, isSQLPingable, isRouterPingable,
		routerPingResults, serverPingResults, sqlPingResults) values (
			@cServerName,
			@cFriendlyName,
			@bIsServerPingable,
			@bIsSQLPingable,
			@bIsRouterPingable,
			@cRouterMessage, @cServerMessage, @cSQLMessage
			)

	drop table #sqlPing

	if (@bIsSQLPingable = 0 or @bIsServerPingable = 0 or @bIsRouterPingable = 0) and @bIsEnabled = 1
	begin
		set @cThisSubject = 'Server ' + @cFriendlyName + ' is not accessible at ' + convert(varchar(40), getDate(), 120) + '!'

		set @nTimesUnavailable = (
				select count(*) + 1
					from notificationLog  (nolock)
					where subject like 'Server ' + @cFriendlyName + ' is not accessible%'
						and (serverName = @cServerName or serverName = @cFriendlyName)
						and ymd >= dateAdd(minute, -15, getDate())
				)

		if @nTimesUnavailable is null
			set @nTimesUnavailable = 1

		set @cThisMessage = 'Contact could not be made with ' + @cFriendlyName +
			char(13) +
			char(13) +
			'In the last 15 minutes, contact could not be made on ' + convert(varchar(20), @nTimesUnavailable) + ' separate attempts.' +
			char(13)

		set @cThisMessage = @cThisMessage + char(13) +
--			'Router Results : ' + char(13) + @cRouterMessage + char(13) + char(13) +
			'Server Results : ' + char(13) + @cServerMessage + char(13) + char(13) +
			'SQLPing Results : ' + char(13) + @cSQLMessage

		-- if it's business hours, or this is the third one we've seen in the last 90 minutes then raise the alert
		if @bIsBusinessHours = 1
			or (
				@bIsBusinessHours = 0
				and @nOffHoursPriority = 1
			)
		begin
			insert into notificationLog_stage (message, severity, subject, serverName, isConnectivity)
				values (@cThisMessage, 1, @cThisSubject, @cFriendlyName, 1)

		end
		else
		begin
			insert into notificationLog_stage (message, severity, subject, serverName, isConnectivity)
				values (@cThisMessage, 2, @cThisSubject, @cFriendlyName, 1)
		end

		return 0
	end
	else
		return 1
end


GO
