/****** Object:  UserDefinedFunction [dbo].[fn_returnApacheRow]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select top 1 *
--		from sandbox.dbo.shopDAPweblogs a
--		cross apply dbo.fn_returnApacheRow(a.widestring, a.filename, a.filepath) b
----	where a.filename like '%access_log%'
--	where a.filename like '%error_log%'
----		where a.ukey = 3971268

CREATE function [dbo].[fn_returnApacheRow] (@cWideString varchar(8000), @cFileName varchar(8000), @cFilePath varchar(8000))

returns @results table (hostname varchar(500), clientIP varchar(500), string1 varchar(500), ymdstring varchar(500), ymd datetime, httpMethod varchar(8000), httpResponse int, bytes int, referer1 varchar(8000),
	useragent varchar(8000), requestID varchar(100), referer2 varchar(8000), logfile varchar(8000), number2 int, number3 varchar(50), MD5hash varchar(100), string2 varchar(500), httprequest varchar(8000),
	errorType varchar(500), PID varchar(100), ErrorMessage varchar(8000), string3 varchar(500))
as
begin

	declare @cDelimiter varchar(5) = ' '
	declare @cString varchar(8000)
	declare @nCurrentItem int
	declare @cResults varchar(8000)
	declare @nCounter int
	declare @nPosition int
	declare @nStringLength int
	declare @bInString bit = 0
	declare @nQuotedStringEnds int = 0
	declare @cStringOpen varchar(1) = ''
	declare @nThisItem int = 1
	declare @cOriginalDelimiter varchar(5) = @cDelimiter

	declare @cHostname varchar(500)
	declare @cClientIP varchar(500)
	declare @cString1 varchar(500)
	declare @cYmdstring varchar(500)
	declare @cYmd datetime
	declare @cHttpMethod varchar(8000)
	declare @nHttpResponse int
	declare @nBytes int
	declare @cReferer1 varchar(8000)
	declare @cUseragent varchar(8000)
	declare @cRequestID varchar(100)
	declare @cReferer2 varchar(8000)
	declare @cLogfile varchar(8000)
	declare @nNumber2 int
	declare @cNumber3 varchar(50)
	declare @cMD5hash varchar(100)
	declare @cString2 varchar(500)
	declare @cString3 varchar(500)
	declare @cHttprequest varchar(8000)
	declare @cErrorType varchar(500)
	declare @cPID varchar(100)
	declare @cErrorMessage varchar(8000)

	declare @cThisString varchar(8000)


	if @cFileName like '%amazon_ip.log%'
		or @cFileName in ('access_combined_SOMEDOMAIN.log', 'amazon_ip.log', 'facebook.log', 'ip.log', 'README.archive')
	begin
		insert into @results (Hostname, ClientIP , String1 , Ymdstring , Ymd, HttpMethod , HttpResponse, bytes, Referer1 , Useragent ,
				RequestID, Referer2, Logfile , Number2, Number3, MD5hash, String2 , Httprequest , ErrorType , PID, ErrorMessage, string3)
			values (
				@cHostname, @cClientIP , @cString1 , @cYmdstring , @cYmd, @cHttpMethod , @nHttpResponse, @nBytes, @cReferer1 , @cUseragent , @cRequestID,
				@cReferer2, @cLogfile , @nNumber2, @cNumber3, @cMD5hash, @cString2 , @cHttprequest , @cErrorType , @cPID, @cErrorMessage, @cString3)
		return
	end

	--if charindex('[', @cString) > 0 and charindex(']', @cString) > 0
	--	set @cString = replace(replace(@cString, '[', '"'), ']', '"')

	if @cFileName like '%access_log%' or @cFileName = 'www.example.com'
		set @cWidestring = replace(@cWidestring, ', ', ',')

	set @cDelimiter = '**'
	set @cWidestring = replace(@cWidestring, '**/', '*/')
	set @cWidestring = replace(@cWidestring, @cOriginalDelimiter, '**')

	--print @cWidestring

	-- scan our string for delims within quoted strings and remove them
	set @nStringLength = len(@cWidestring)
	set @nPosition = 1
	set @nCurrentItem = 1
	set @cThisString = ''

	while @nPosition <= @nStringLength
	begin
		set @cThisString = @cThisString + substring(@cWideString, @nPosition, 1)

		-- if we are in a string, we are looking to close that string out
		if @bInString = 1
		begin
			-- we are on the lookout for trash characters within our strings, since Apache sucks
			if substring(@cWidestring, @nPosition, 1) in ('"', '[', ']')
				and @nPosition <= @nQuotedStringEnds
			begin
				-- in this instance we are inside a quoted string and need to ignore our delim and terms
				set @cWidestring = left(@cWidestring, @nPosition - 1) + '*' + substring(@cWidestring, @nPosition + 1, 8000)
			end

			if substring(@cWidestring, @nPosition, len(@cDelimiter)) = @cDelimiter
				and @nPosition <= @nQuotedStringEnds
			begin
				-- in this instance we are inside a quoted string and need to ignore our delim and terms
				set @cWidestring = left(@cWidestring, @nPosition - 1) + @cOriginalDelimiter + substring(@cWidestring, @nPosition + len(@cDelimiter), 8000)

				set @nQuotedStringEnds = @nQuotedStringEnds - (len(@cDelimiter) - len(@cOriginalDelimiter))
			end


			if (substring(@cWideString, @nPosition + 1, len(@cDelimiter)) = @cDelimiter or @nPosition = len(@cWideString))
				and (
					substring(@cWidestring, @nPosition, 1) = '"' and @cStringOpen = '"'
					or substring(@cWidestring, @nPosition, 1) = ']' and @cStringOpen = '['
					)
			begin
				set @bInString = 0
				set @nPosition = @nPosition + 1 + len(@cDelimiter) -- the quote or brace, plus the length of the delim
				set @cStringOpen = ''
				set @nQuotedStringEnds = 0
				set @cThisString = left(@cThisString, len(@cThisString) - 1)

				-- print convert(varchar(20), @nCurrentItem) + ': ' + left(@cThisString, len(@cThisString) - 1) + ' (quoted string)'

				GOTO SETVARIABLES
			end

			if substring(@cWidestring, @nPosition, len(@cDelimiter)) = @cDelimiter
			begin
				-- in this instance we are inside a quoted string and need to ignore our delim
				set @cWidestring = left(@cWidestring, @nPosition - 1) + @cOriginalDelimiter + substring(@cWidestring, @nPosition + len(@cDelimiter), 8000)
			end
		end

		-- if we are starting a new string
		if substring(@cWidestring, @nPosition, 1) in ('"', '[')
			and @bInString = 0
			and (substring(@cWideString, @nPosition - len(@cDelimiter), len(@cDelimiter)) = @cDelimiter or @nPosition = 1)
		begin
			set @cStringOpen = substring(@cWidestring, @nPosition, 1)
			set @bInString = 1
			set @cThisString = ''

			--print 'in string (' + @cStringOpen + ')'

			if substring(@cWidestring, @nPosition, 7) = '"GET**/'
				or substring(@cWidestring, @nPosition, 8) = '"POST**/'
			begin
				-- this is hard-coding for weblogs
				--print 'hard coded'
				set @cThisString = ''

				-- we know the string ends with this, so we need to eat any malicious characters within the quoted string
				if charindex('**HTTP/', substring(@cWidestring, @nPosition, 8000)) > 0
					set @nQuotedStringEnds = @nPosition + charindex('**HTTP/', substring(@cWidestring, @nPosition, 8000)) + 1
				else
					set @nQuotedStringEnds = 0

				--print 'quoted string ends'
				--print @cWidestring
				--print @nQuotedStringEnds
			end
		end

		if (substring(@cWideString, @nPosition, len(@cDelimiter)) = @cDelimiter and not (@cFileName like 'modsec_audit.log%' and @nCurrentItem in (8,11)))
			or (substring(@cWideString, @nPosition, 3) = '**"' and (@cFileName like 'modsec_audit.log%' and @nCurrentItem = 8))
			or (substring(@cWideString, @nPosition, 3) = '**/' and (@cFileName like 'modsec_audit.log%' and @nCurrentItem = 11))
			or @nPosition = len(@cWideString)
		begin
			--print 'end string'

			--print convert(varchar(20), @nCurrentItem) + ': ' + left(@cThisString, len(@cThisString) - 1)
			set @cThisString = left(@cThisString, len(@cThisString) - 1)

			set @nPosition = @nPosition + len(@cDelimiter)

			GOTO SETVARIABLES
		end
		else
			set @nPosition = @nPosition + 1

		continue

		SETVARIABLES:
		begin
			--print convert(varchar(20), @nCurrentItem) + ': ' + @cThisString

			set @cString = replace(@cThisString, '*', ' ')

			if @cFileName like 'modsec_audit.log%'
			begin
				if @nCurrentItem = 1
					set @cHostname = rtrim(ltrim(@cString))
				if @nCurrentItem = 2
					set @cClientIP = rtrim(ltrim(@cString))
				if @nCurrentItem = 3
					set @cString1 = rtrim(ltrim(@cString))
				if @nCurrentItem = 4
					set @cYmdstring = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
				if @nCurrentItem = 5
					set @cHttprequest = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 6 and rtrim(ltrim(@cString)) <> '-'
					set @nHttpResponse = rtrim(ltrim(@cString))
				if @nCurrentItem = 7 and rtrim(ltrim(@cString)) <> '-'
					set @nBytes = rtrim(ltrim(@cString))
				if @nCurrentItem = 8
					set @cReferer1 = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 9
					set @cUseragent = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 10
					set @cRequestID = rtrim(ltrim(@cString))
				if @nCurrentItem = 11
					set @cReferer2 = rtrim(ltrim(@cString))
				if @nCurrentItem = 12
					set @cLogfile = rtrim(ltrim(@cString))
				if @nCurrentItem = 13 and rtrim(ltrim(replace(@cString, '"', ''))) <> '-'
					set @nNumber2 = rtrim(ltrim(@cString))
				if @nCurrentItem = 14
					set @cNumber3 = rtrim(ltrim(@cString))
				if @nCurrentItem = 15
					set @cMD5hash = rtrim(ltrim(@cString))
			end

			if @cFileName like '%access_log%'
			begin
				-- this is a hack to fix a change in log file format where a field was added
				if @nCurrentItem = 4 and left(right(rtrim(ltrim(@cString)), 5), 1) = '-' and len(@cString) > 15
				begin
					--print 'skipping ahead'
					set @nCurrentItem = 5
				end

				if @nCurrentItem = 1
					set @cHostName = rtrim(ltrim(@cString))
				if @nCurrentItem = 2
					set @cClientIP = rtrim(ltrim(@cString))
				if @nCurrentItem = 3
					set @cString1 = rtrim(ltrim(@cString))
				if @nCurrentItem = 4
					set @cString2 = rtrim(ltrim(@cString))
				if @nCurrentItem = 5
					set @cYmdstring = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
				if @nCurrentItem = 6
					set @cHttprequest = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 7 and rtrim(ltrim(replace(@cString, '"', ''))) <> '-'
					set @nHttpResponse = rtrim(ltrim(@cString))
				if @nCurrentItem = 8 and rtrim(ltrim(replace(@cString, '"', ''))) <> '-'
					set @nBytes = rtrim(ltrim(@cString))
				if @nCurrentItem = 9
					set @cString3 = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 10
					set @cUseragent = rtrim(ltrim(replace(@cString, '"', '')))
			end

			if @cFileName like '%error_log%'
			begin
				if @nCurrentItem = 5
				begin
					set @cString = @cString + ' ' + replace(substring(@cWidestring, @nPosition, 8000), '**', @cOriginalDelimiter)
					set @nPosition = len(@cWideString) + 1
				end

				if @nCurrentItem = 1
					set @cYmdstring = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
				if @nCurrentItem = 2
					set @cErrorType = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
				if @nCurrentItem = 3
					set @cPID = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
				if @nCurrentItem = 4
					set @cClientIP = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
				if @nCurrentItem = 5
					set @cErrorMessage = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
			end

			if (@cFilePath like '%\domlogs\%' or @cFilePath like '%\access_logs\%' or @cFileName like '%www.example.com' or @cFileName like '%www.example.com-ssl_log')
				and not @cFileName like '%bytes_log'
				and not @cFileName like 'ftp%'
				and not @cFileName like '%.log'
				and not @cFileName like '%.gz'
			begin
				if @nCurrentItem = 4 and rtrim(ltrim(@cString)) = '-'
					set @nCurrentItem = 3

				if @nCurrentItem = 1
					set @cClientIP = rtrim(ltrim(@cString))
				if @nCurrentItem = 2
					set @cString1 = rtrim(ltrim(@cString))
				if @nCurrentItem = 3
					set @cString2 = rtrim(ltrim(@cString))
				if @nCurrentItem = 4
					set @cYMDString = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
				if @nCurrentItem = 5
					set @cHttprequest = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 6 and rtrim(ltrim(replace(@cString, '"', ''))) <> '-'
					set @nHttpResponse = rtrim(ltrim(@cString))
				if @nCurrentItem = 7 and rtrim(ltrim(replace(@cString, '"', ''))) <> '-'
					set @nBytes = rtrim(ltrim(@cString))
				if @nCurrentItem = 8
					set @cReferer1 = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 9
					set @cUseragent = rtrim(ltrim(replace(@cString, '"', '')))
			end

			if @cFileName in ('facebook.log', 'amazon.log', 'checkout.log', 'amazon_ip.log')
			begin
				if @nCurrentItem = 1
					set @cClientIP = rtrim(ltrim(@cString))
				if @nCurrentItem = 2
					set @cString1 = rtrim(ltrim(@cString))
				if @nCurrentItem = 3
					set @cString2 = rtrim(ltrim(@cString))
				if @nCurrentItem = 4
					set @cString3 = rtrim(ltrim(@cString))
				if @nCurrentItem = 5
					set @cYMDString = rtrim(ltrim(replace(replace(@cString, '[', ''), ']', '')))
				if @nCurrentItem = 6
					set @cHttprequest = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 7
					set @nHttpResponse = rtrim(ltrim(@cString))
				if @nCurrentItem = 8
					set @nBytes = rtrim(ltrim(@cString))
				if @nCurrentItem = 9
					set @cReferer1 = rtrim(ltrim(replace(@cString, '"', '')))
				if @nCurrentItem = 10
					set @cUseragent = rtrim(ltrim(replace(@cString, '"', '')))
			end

			set @cThisString = ''
			set @nCurrentItem = @nCurrentItem + 1
			continue
		end
	end


	set @cHTTPMethod = ''

	if @cHttprequest like 'GET %'
		set @cHTTPMethod = 'GET'
	if @cHttprequest like 'POST %'
		set @cHTTPMethod = 'POST'
	if @cHttprequest like 'OPTIONS %'
		set @cHTTPMethod = 'OPTIONS'


	insert into @results (Hostname, ClientIP , String1 , Ymdstring , Ymd, HttpMethod , HttpResponse, bytes, Referer1 , Useragent ,
			RequestID, Referer2, Logfile , Number2, Number3, MD5hash, String2 , Httprequest , ErrorType , PID, ErrorMessage, string3)
		values (
			@cHostname, @cClientIP , @cString1 , @cYmdstring , @cYmd, @cHttpMethod , @nHttpResponse, @nBytes, @cReferer1 , @cUseragent , @cRequestID,
			@cReferer2, @cLogfile , @nNumber2, @cNumber3, @cMD5hash, @cString2 , @cHttprequest , @cErrorType , @cPID, @cErrorMessage, @cString3)

	return
end
GO
