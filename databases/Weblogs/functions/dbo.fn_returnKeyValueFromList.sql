/****** Object:  UserDefinedFunction [dbo].[fn_returnKeyValueFromList]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select dbo.fn_returnKeyValueFromList('category=widgets&year=0&model=standard&stocknumber=04815522ad&ukey_product=42204521', 'ukey_product', '&')
CREATE function [dbo].[fn_returnKeyValueFromList] (@cList varchar(8000), @cKeyName varchar(100), @cDelimiter varchar(5))
returns varchar(8000)
as
begin

	if charindex(@cKeyName, @cList) = 0
		return null

	declare @cString varchar(500)
	declare @nDelimiterFound int
	declare @nDelimiterLength int
	declare @cKeyNameFound varchar(500)
	declare @cKeyValue varchar(8000)

	if @cDelimiter = ' '
		set @nDelimiterLength = 1
	else
		set @nDelimiterLength = len(@cDelimiter)

	while len(@cList) > 0
	begin
		set @nDelimiterFound = charindex(@cDelimiter, @cList)

		if @nDelimiterFound > 0
		begin
			set @cString = left(@cList, charindex(@cDelimiter, @cList) - 1)
			set @cList = substring(@cList, charindex(@cDelimiter, @cList)+@nDelimiterLength, 8000)
		end
		else
		begin
			set @cString = @cList
			set @cList = ''
		end

		if @nDelimiterFound > 0 or len(@cString) > 0
		begin
			set @cString = rtrim(ltrim(@cString))

			set @cKeyNameFound = rtrim(ltrim(replace(left(@cString, charindex('=', @cString)), '=', '')))
			set @cKeyValue = rtrim(ltrim(replace(substring(@cString, charindex('=', @cString), 8000), '=', '')))

			if @cKeyName = @cKeyNameFound
				return @cKeyValue
		end
		else
			set @cList = ''
	end

	return null
end



GO
