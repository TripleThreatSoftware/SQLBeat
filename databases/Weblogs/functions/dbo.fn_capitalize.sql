CREATE function [fn_capitalize] (@cString varchar(500))
returns varchar(500)
as
begin
	declare @nCounter int
	declare @lLastWasSpace bit
	declare @cReturnString varchar(500)
	set @nCounter = 1
	set @lLastWasSpace = 0
	set @cReturnString = ''

	while @nCounter <= len(@cString)
	begin
		if @nCounter = 1 or @lLastWasSpace = 1
			set @cReturnString = @cReturnString + upper(substring(@cString, @nCounter, 1))
		else
			set @cReturnString = @cReturnString + substring(@cString, @nCounter, 1)

		if substring(@cString, @nCounter, 1) = ' '
			set @lLastWasSpace = 1
		else
			set @lLastWasSpace = 0

		set @nCounter = @nCounter + 1
	end

	return @cReturnString
end



GO
