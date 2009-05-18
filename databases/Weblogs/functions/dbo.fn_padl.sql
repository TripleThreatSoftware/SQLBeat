/****** Object:  UserDefinedFunction [dbo].[fn_padl]    Script Date: 05/19/2009 13:59:31 ******/
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
/****** Object:  UserDefinedFunction [dbo].[fn_padl]    Script Date: 05/19/2009 13:59:47 ******/
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
