create function [fn_padl] (@cString varchar(200), @nLength int, @cPadCharacter varchar(1))
	returns varchar(200)
as
begin
	while len(@cString) < @nLength
		set @cString = @cPadCharacter + @cString

	return @cString
end



GO
