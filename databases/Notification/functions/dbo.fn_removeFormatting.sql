ALTER function [dbo].[fn_removeFormatting](@cString varchar(8000))
returns varchar(8000)
as
begin
	declare @cReturnString varchar(8000)
--	declare @nCounter int
--	declare @cCharacter varchar(1)
--	set @nCounter = 1
--	set @cReturnString = ''
--
--	while @nCounter <= len(@cString)
--	begin
--		set @cCharacter = substring(@cString, @nCounter, 1)
--		if @cCharacter not in (space(1), char(9), char(13))
--			set @cReturnString = @cReturnString + @cCharacter
--
--		set @nCounter = @nCounter + 1
--	end

	set @cReturnString = replace(replace(replace(replace(@cString, space(1), space(0)), char(9), space(0)), char(13), space(0)), char(10), space(0))

	return @cReturnString
end
