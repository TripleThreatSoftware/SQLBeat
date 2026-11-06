/****** Object:  UserDefinedFunction [dbo].[fn_returnKeyValue]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE function [dbo].[fn_returnKeyValue] (@cString varchar(500), @cKey varchar(100))
returns varchar(200)
as
begin
	if charindex(@cKey, @cString) = 0 or charindex('=', @cString) = 0 or charindex(';', @cString) = 0
		return ''

	declare @cValue varchar(200)

	if len(@cString) - charindex(@cKey, @cString) <= 0
		return ''
	set @cString = right(@cString, len(@cString) - charindex(@cKey, @cString) + 1)

	if len(@cString) - charindex('=', @cString) <= 0
		return ''
	set @cString = right(@cString, len(@cString) - charindex('=', @cString))

	if charindex(';', @cString)-1 <= 0
		return @cString
	set @cValue = left(@cString, charindex(';', @cString)-1)

	return @cValue
end
GO
