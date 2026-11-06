/****** Object:  UserDefinedFunction [dbo].[fn_returnFormattedInt]    Script Date: 11/6/2026 9:52:52 AM ******/
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
	set @cReturnString = isnull(left(@cReturnString, len(@cReturnString) - 3), '')

	return @cReturnString
end
-- select dbo.fn_returnFormattedInt(12345)
GO
