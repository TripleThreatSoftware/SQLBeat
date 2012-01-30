declare @cSQlString nvarchar(4000)
declare @dLastEventLogCheck dateTime
declare @cDateString varchar(50)

set @dLastEventLogCheck = DATEADD(hour, -3, getdate())


set @cDateString =
		right('00' + convert(varchar(2), datePart(month, @dLastEventLogCheck)), 2) + '-' +
		right('00' + convert(varchar(2), datePart(day, @dLastEventLogCheck)), 2) + '-' +
		convert(varchar(4), datePart(year, @dLastEventLogCheck)) + ' ' +

		right('00' + convert(varchar(2), datePart(hour, @dLastEventLogCheck)), 2) + ':' +
		right('00' + convert(varchar(2), datePart(minute, @dLastEventLogCheck)), 2) + ':' +
		right('00' + convert(varchar(2), datePart(second, @dLastEventLogCheck)), 2) + '.000'

set @cSQLString = 'powershell -file c:\shared\readevents.ps1 -cServerName "web03" -cUserName "web03\administrator" -cPassword "REDACTED" -cTimestamp ' + @cDateString
print @cSQLString

exec master..xp_cmdshell @cSQlString


dbo.fn_returnUTCDate(@dLastEventLogCheck)

select top 100 * from eventLog order by timeWritten desc

exec master..xp_cmdshell 'powershell -file c:\shared\readevents2.ps1 -cServerName web03 -cUserName "web03\administrator" -cPassword "REDACTED" -cTimestamp "01-27-2012 20:30"'
