CREATE  function [dbo].[fn_returnListItem] (@cList varchar(8000), @nItemNumber int, @cDelimiter varchar(5))
returns varchar(8000)
as
begin
	declare @cString varchar(8000)
	declare @nCurrentItem int
	declare @cResults varchar(8000)

	if @cDelimiter = space(1)
	begin
		set @cDelimiter = '**'
		set @cList = replace(@cList, space(1), '**')
	end

	set @nCurrentItem = 0
	set @cResults = ''

	while len(@cList) > 0
	begin
		-- skip if the first chars are the delimiter
		if left(@cList, len(@cDelimiter)) = @cDelimiter
			set @cList = right(@cList, len(@cList) - len(@cDelimiter))

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
					while dbo.fn_occurs('"', @cString) % 2 <> 0 and charindex(@cDelimiter, @cList) > 0
					begin
						set @cString = @cString + @cDelimiter + left(@cList, charindex(@cDelimiter, @cList) - 1)
						set @cList = substring(@cList, charindex(@cDelimiter, @cList)+len(@cDelimiter), 8000)
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
