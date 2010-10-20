/****** Object:  UserDefinedFunction [dbo].[fn_returnFormattedNumber]    Script Date: 10/20/2010 11:53:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select dbo.fn_returnFormattedNumber(12345)
-- select dbo.fn_returnFormattedNumber(12345.67)

create function [dbo].[fn_returnFormattedNumber] (@cNumber varchar(500))
returns varchar(500)
as
begin
	declare @cReturnString varchar(500)

	-- in this case, it's a floater
	if charindex('.', @cNumber) > 0
		set @cReturnString = convert(varchar(500), convert(money, @cNumber), 1)
	else
		set @cReturnString = reverse(substring(reverse(convert(varchar(500), convert(money, @cNumber), 1)), 4, 20))
--		set @cReturnString = left(@cReturnString, len(@cReturnString) - 3)

	return @cReturnString
end
GO
