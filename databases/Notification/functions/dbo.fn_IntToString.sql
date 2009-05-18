SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[fn_IntToString]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_IntToString] (@nNumber bigint)
returns varchar(100)
as
begin
	declare @cReturnString varchar(100)
	set @cReturnString = reverse(substring(reverse(convert(varchar(20), convert(money, @nNumber), 1)), 4, 20))

	return @cReturnString

end
-- select dbo.fn_IntToString(1234567)
GO
