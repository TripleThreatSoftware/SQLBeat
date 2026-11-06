/****** Object:  UserDefinedFunction [dbo].[fn_padr]    Script Date: 11/6/2026 9:47:51 AM ******/
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
