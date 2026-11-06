/****** Object:  UserDefinedFunction [dbo].[fn_returnListItem]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select dbo.fn_returnListItem ('', 3, ',')
--select dbo.fn_returnListItem ('', 4, ',')
-- select dbo.fn_returnListItem(replace('/Triumph__Speed-TripleR/Tools-and-Manuals.html', '/', '_'), 2, '_')

CREATE function [dbo].[fn_returnListItem] (@cList varchar(8000), @nItemNumber int, @cDelimiter varchar(5))
returns varchar(8000)
as
begin
	declare @cString varchar(8000)
	declare @nCurrentItem int
	declare @cResults varchar(8000)
	declare @nCounter int

	if charindex('[', @cString) > 0 and charindex(']', @cString) > 0
		set @cString = replace(replace(@cString, '[', '"'), ']', '"')

	if @cDelimiter = space(1)
	begin
		set @cDelimiter = '**'
		set @cList = replace(@cList, space(1), '**')
	end

	set @nCurrentItem = 0
	set @cResults = ''

	-- skip if the first chars are the delimiter
	if left(@cList, len(@cDelimiter)) = @cDelimiter
		set @cList = right(rtrim(ltrim(@cList)), len(@cList) - len(@cDelimiter))


	while len(@cList) > 0
	begin

		if charindex(@cDelimiter, @cList) > 0
		begin
			set @cString = left(@cList, charindex(@cDelimiter, @cList) - 1)
			set @cList = substring(@cList, charindex(@cDelimiter, @cList)+len(@cDelimiter), 8000)

			if charindex('"', @cString) > 0
			begin
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
