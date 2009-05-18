/****** Object:  UserDefinedFunction [dbo].[fn_padr]    Script Date: 05/19/2009 13:59:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE    function [dbo].[fn_padr] (@cString varchar(200), @nLength int, @cPadCharacter varchar(1))
	returns varchar(200)
as
begin

	if @cPadCharacter = ' '
		return @cString + space(@nLength - len(@cString))
	else
	begin
		while len(@cString) < @nLength
			set @cString = @cString + @cPadCharacter

	end

	return @cString

end
GO
