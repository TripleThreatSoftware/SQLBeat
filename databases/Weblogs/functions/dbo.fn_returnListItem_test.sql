/****** Object:  UserDefinedFunction [dbo].[fn_returnListItem_test]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select dbo.fn_returnListItem ('', 3, ',')
--select dbo.fn_returnListItem ('', 4, ',')
-- select dbo.fn_returnListItem(replace('/Triumph__Speed-TripleR/Tools-and-Manuals.html', '/', '_'), 2, '_')

CREATE function [dbo].[fn_returnListItem_test] (@cList varchar(8000), @nItemNumber int, @cDelimiter varchar(5))
returns varchar(8000)
as
begin
	declare @cString varchar(8000)
	declare @nCurrentItem int
	declare @cResults varchar(8000)
	declare @nCounter int
	declare @nPosition int
	declare @nStringLength int
	declare @bInString bit = 0
	declare @nQuotedStringEnds int = 0
	declare @cStringOpen varchar(1) = ''
	declare @cOriginalDelimiter varchar(5) = @cDelimiter

	if charindex('[', @cString) > 0 and charindex(']', @cString) > 0
		set @cString = replace(replace(@cString, '[', '"'), ']', '"')

	set @cDelimiter = '**'
	set @cList = replace(@cList, @cOriginalDelimiter, '**')

	-- scan our string for delims within quoted strings and remove them
	set @nStringLength = len(@cList)
	set @nPosition = 1

	while @nPosition <= @nStringLength
	begin
		if @bInString = 1
		begin
			if substring(@cList, @nPosition, 1) in ('"', '[', ']')
				and @nPosition <= @nQuotedStringEnds
			begin
				-- in this instance we are inside a quoted string and need to ignore our delim
				set @cList = left(@cList, @nPosition - 1) + '*' + substring(@cList, @nPosition + len(@cDelimiter), 8000)
			end


			if substring(@cList, @nPosition, 1) = '"' and @cStringOpen = '"'
				or substring(@cList, @nPosition, 1) = ']' and @cStringOpen = '['
			begin
				set @bInString = 0
				set @nPosition = @nPosition + 1
				set @cStringOpen = ''
				set @nQuotedStringEnds = 0
				continue
			end

			if substring(@cList, @nPosition, len(@cDelimiter)) = @cDelimiter
			begin
				-- in this instance we are inside a quoted string and need to ignore our delim
				set @cList = left(@cList, @nPosition - 1) + @cOriginalDelimiter + substring(@cList, @nPosition + len(@cDelimiter), 8000)
			end
		end

		if substring(@cList, @nPosition, 1) in ('"', '[') and @bInString = 0
		begin
			set @cStringOpen = substring(@cList, @nPosition, 1)
			set @bInString = 1

			if substring(@cList, @nPosition, 7) = '"GET**/'
				or substring(@cList, @nPosition, 8) = '"POST**/'
			begin
				-- this is hard-coding for weblogs

				-- we know the string ends with this, so we need to eat any malicious characters within the quoted string
				if charindex('**HTTP/', substring(@cList, @nPosition, 8000)) > 0
					set @nQuotedStringEnds = @nPosition + charindex('**HTTP/', substring(@cList, @nPosition, 8000)) + 1
				else
					set @nQuotedStringEnds = 0
			end
		end

		set @nPosition = @nPosition + 1
	end

	set @nCurrentItem = 0
	set @cResults = ''

	-- take one character bites from the list until the delimiter is found
	while len(@cList) > 0
	begin
		-- skip if the first chars are the delimiter
		if left(@cList, len(@cDelimiter)) = @cDelimiter and @nCurrentItem = 0
			set @cList = right(@cList, len(@cList) - len(@cDelimiter))

		if charindex(@cDelimiter, @cList) > 0
		begin
			-- take a bite of the string up to the next instance of the delimiter
			set @cString = left(@cList, charindex(@cDelimiter, @cList) - 1)

			-- start the list over again after the delim
			set @cList = substring(@cList, charindex(@cDelimiter, @cList)+len(@cDelimiter), 8000)

			-- if we find we have a quoted string within our bite, we need to continue our bite until the string ends and we find the next delim
			if charindex('"', @cString) > 0
			begin
				-- if we are at the end of our string and there are no quotes left, then end the loop and return what we have
				if charindex(@cDelimiter, @cList) = 0 and dbo.fn_occurs('"', @cString) = 1
				begin
					set @cString = @cString + @cDelimiter + @cList
					set @cList = ''
				end
				else
				begin
					set @nCounter = 0

					while dbo.fn_occurs('"', @cString) % 2 <> 0
						and (
							charindex(@cDelimiter, @cList) > 0
							or RIGHT(@cList, 1) = '"'
							)
						and @nCounter < 8000
						and LEN(@cList) > 0
					begin

						if charindex(@cDelimiter, @cList) > 0
						begin
							set @cString = @cString + @cDelimiter + left(@cList, charindex(@cDelimiter, @cList) - 1)
							set @cList = substring(@cList, charindex(@cDelimiter, @cList)+len(@cDelimiter), 8000)
						end
						else
						begin
							if RIGHT(@cList, 1) = '"'
							begin
								set @cString = @cString + @cDelimiter + @cList
								set @cList = ''
							end
						end

						set @nCounter = @nCounter + 1

					end
				end
			end
		end
		else
		begin
			set @cString = @cList
			set @cList = ''
		end

		set @nCurrentItem = @nCurrentItem + 1
		if @nCurrentItem = @nItemNumber
		begin
			set @cResults = rtrim(ltrim(@cString))
			return @cResults
		end
	end

	return @cResults
end
GO
