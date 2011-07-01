SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select top 10 * from notification..messagesSent order by ymd desc
-- select * from query

ALTER procedure [dbo].[pr_processQueries]
as
begin
	declare @nUkey int
	declare @nUkeyRecipient int
	declare @cSQLString nvarchar(4000)
	declare @cUserName varchar(200)
	declare @cPassword varchar(200)
	declare @cServerName varchar(200)
	declare @cCommandText varchar(8000)
	declare @nUkeyQuery int
	declare @cMessage varchar(8000)
	declare @cQueryName varchar(8000)
	declare @cSubject varchar(8000)
	declare @bSendOutput bit
	declare @bSendAlert bit
	declare @cExpectedValue varchar(8000)
	declare @cAlertValue varchar(8000)
	declare @cOutput varchar(8000)
	declare @cRecipient varchar(500)
	declare @cDatabaseName varchar(1000)
	declare @cCleanOutput varchar(8000)
	declare @nMinValue int
	declare @nMaxValue int

--print 'starting'

	create table #output (ukey int identity, nastyLine varchar(8000))

	select identity(int) as ukey,
		a.serverName, a.userName, a.password, a.databaseName, a.commandText,
		a.sendOutput, a.sendAlert, a.expectedValue, a.alertValue,
		a.ukey as ukey_query, a.queryName, minValue, maxValue
		into #queries
		from query a (nolock)
		join querySchedule b (nolock) on a.ukey = b.ukey_query
			and (
				(onMonday = 1 and dateName(weekDay, getDate()) = 'Monday')
				or (onTuesday = 1 and dateName(weekDay, getDate()) = 'Tuesday')
				or (onWednesday = 1 and dateName(weekDay, getDate()) = 'Wednesday')
				or (onThursday = 1 and dateName(weekDay, getDate()) = 'Thursday')
				or (onFriday = 1 and dateName(weekDay, getDate()) = 'Friday')
				or (onSaturday = 1 and dateName(weekDay, getDate()) = 'Saturday')
				or (onSunday = 1 and dateName(weekDay, getDate()) = 'Sunday')
				)
			and (
				isnull(a.lastRun, '') = ''
				or dateDiff(minute, a.lastRun, getDate()) >= isnull(b.minuteInterval, 0)
				)
			and (
				(isnull(startHour, 0) = 0 and isnull(endHour, 0) = 0)
				or (datePart(hour, getDate()) between startHour and endHour)
				)
		where a.isEnabled = 1
		order by a.lastRun

	set @nUkey = 0

--print 'selected queries'

	while exists (select top 1 ukey from #queries where ukey > @nUkey)
	begin
		truncate table #output

		select top 1
			@nUkey = ukey,
			@cServerName = serverName,
			@cUserName = userName,
			@cPassword = password,
			@cDatabaseName = databaseName,
			@cCommandText = commandText,
			@nUkeyQuery = ukey_query,
			@cQueryName = queryName,
			@bSendOutput = sendOutput,
			@bSendAlert = sendAlert,
			@cExpectedValue = expectedValue,
			@cAlertValue = alertValue,
			@nMinValue = minValue,
			@nMaxValue = maxValue
			from #queries
			where ukey > @nUkey
			order by ukey

--		print 'Running query "' + @cQueryName + '" against ' + @cServerName

		set @cCommandText = 'set nocount on; ' + @cCommandText

		-- This is what will be sent
		set @cMessage = ''
		set @cSubject = ''
		set @cOutput = ''

		set @cSQLString = 'osql -S' + @cServerName + ' ' +
			case when isnull(@cUserName, '') <> '' then '-U' + @cUserName + ' ' else '' end +
			case when isnull(@cPassword, '') <> '' then '-P' + @cPassword + ' ' else '' end +
			case when isnull(@cPassword, '') = '' and isnull(@cUserName, '') = '' then '-E ' else '' end +
			'-n -h-1 -w300 ' +
			case when isnull(@cDatabaseName, '') <> '' then '-d' + @cDatabaseName + ' ' else '' end +
			'-q"' + @cCommandText + '"'

		insert into #output (nastyLine)
		exec master..xp_cmdShell @cSQLString

		delete from #output where nastyLine = '' or nastyLine = 'null' or nastyline like '%dbcc execution completed%' or nastyLine is null

		-- if there's an error, pitch the set and queue an alert
		if (select count(*) from #output where nastyLine like 'msg%level%state%server%line%' or nastyLine like '%incorrect syntax%'  or nastyLine like '%no user selected%') > 0
		begin
			set @cSubject = 'Query "' + @cQueryName + '" failed, and has been disabled at ' + convert(varchar(20), getDate(), 120) + '.'

			select @cMessage = @cMessage + char(13) + isnull(nastyLine, 'NULL LINE')
				from #output
				order by ukey

			update query set isEnabled = 0 where ukey = @nUkeyQuery
		end
		else
		begin
			update #output set nastyLine = rtrim(ltrim(replace(replace(nastyLine, char(13), ''), '  ', ' ')))

			select
				@cOutput = @cOutput + char(13) + isnull(nastyLine, '')
				from #output
				where isnull(rtrim(ltrim(replace(nastyLine, char(9), ''))), '') <> ''
				order by ukey

			-- if we email output each time this runs
			if @bSendOutput = 1
			begin
				set @cSubject = 'Query "' + @cQueryName + '" results at ' + convert(varchar(20), getDate(), 120) + '.'
				set @cMessage = @cOutput
			end
			else
			if @bSendAlert = 1
			begin
				set @cCleanOutput = rtrim(ltrim(replace(replace(@cOutput, char(13) , ''), char(9), '')))

				--print 'Found: ' + @cCleanOutput
				--print 'Alert: ' + @cAlertValue
				--print 'Expected: ' + @cExpectedValue

				if (isnull(@cCleanOutput, '') <> isnull(@cExpectedValue, '') and isnull(@cExpectedValue, '') <> '')
					or (isnull(@cCleanOutput, '') = isnull(@cAlertValue, '') and isnull(@cAlertValue, '') <> '')
					or (isnumeric(@cCleanOutput) = 1 and convert(int, @cCleanOutput) < @nMinValue and @nMinValue is not null)
					or (isnumeric(@cCleanOutput) = 1 and convert(int, @cCleanOutput) > @nMaxValue and @nMaxValue is not null)
				begin
					set @cSubject = 'Query "' + @cQueryName + '" ALERT at ' + convert(varchar(20), getDate(), 120) + '.'
					set @cMessage = @cCommandText + '<br><br>' + @cOutput
				end
			end

		end

		-- if we found something worth reporting
		if isnull(@cSubject, '') <> ''
		begin
			-- iterate through recipients
			set @nUkeyRecipient = 0
			set @cRecipient = ''

			while exists (select top 1 ukey from queryRecipients (nolock) where ukey_query = @nUkeyQuery and ukey > @nUkeyRecipient)
			begin
				select top 1
					@nUkeyRecipient = ukey,
					@cRecipient = emailAddress
					from queryRecipients (nolock)
					where ukey_query = @nUkeyQuery
						and ukey > @nUkeyRecipient
					order by ukey

				--print 'Sending message!'
				--print @cSubject
				--print @cMessage

				exec notification..pr_sendMessage '', @cRecipient, @cSubject, @cMessage, 1
			end
		end

		update query set lastRun = getDate() where ukey = @nUkeyQuery
	end

--print 'done'

	drop table #output
	drop table #queries
end
