/****** Object:  UserDefinedFunction [dbo].[fn_returnKeyValue]    Script Date: 12/04/2009 18:54:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_returnKeyValue] (@cString varchar(8000), @cKey varchar(500), @cDelimiter varchar(20))
returns varchar(2000)
as
begin
	if charindex(@cKey, @cString) = 0 or charindex(@cDelimiter, @cString) = 0
		return ''

	declare @cValue varchar(2000)

	set @cValue = substring(@cString, charindex(@cKey, @cString), 2000)
	if charindex(@cDelimiter, @cValue) <> 0
		set @cValue = left(@cValue, charindex(@cDelimiter, @cValue) - 1)

	if charindex('=', @cValue) <> 0
		set @cValue = substring(@cValue, charindex('=', @cValue) + 1, 2000)

	return @cValue
end
GO
