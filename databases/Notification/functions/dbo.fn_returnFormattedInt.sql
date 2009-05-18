/****** Object:  UserDefinedFunction [dbo].[fn_returnFormattedInt]    Script Date: 05/19/2009 13:59:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_returnFormattedInt] (@nNumber bigint)
returns varchar(50)
as
begin
	declare @cReturnString varchar(50)

	set @cReturnString = convert(varchar(50), convert(money, @nNumber), 1)
	set @cReturnString = left(@cReturnString, len(@cReturnString) - 3)

	return @cReturnString
end
-- select dbo.fn_returnFormattedInt(12345)
GO
