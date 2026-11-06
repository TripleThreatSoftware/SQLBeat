/****** Object:  UserDefinedFunction [dbo].[fn_padl]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select dbo.fn_padl('test', 10, '*')

CREATE function [dbo].[fn_padl] (@cString varchar(200), @nLength int, @cPadCharacter varchar(1))
	returns varchar(200)
as
begin
	set @cString = right(replicate(@cPadCharacter, @nLength) + @cString, @nLength)
--	while len(@cString) < @nLength
--		set @cString = @cPadCharacter + @cString

	return @cString
end
GO
