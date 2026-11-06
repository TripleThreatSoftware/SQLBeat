/****** Object:  UserDefinedFunction [dbo].[fn_padl]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create function [dbo].[fn_padl] (@cString varchar(200), @nLength int, @cPadCharacter varchar(1))
	returns varchar(200)
as
begin
	while len(@cString) < @nLength
		set @cString = @cPadCharacter + @cString

	return @cString
end
GO
