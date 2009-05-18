/****** Object:  UserDefinedFunction [dbo].[fn_returnKeyValuePair]    Script Date: 05/19/2009 13:59:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE function [dbo].[fn_returnKeyValuePair] (@cString varchar(500), @nKeyNumber int, @cPairDelimiter varchar(10))
returns varchar(200)
as
begin
	declare @nCounter int
	declare @cTempString varchar(500)
	set @nCounter = 1

	-- if there's more than one key/value pair in the string
	if charindex(@cPairDelimiter, @cString) > 0
		set @cTempString = substring(@cString, 1, charindex(@cPairDelimiter, @cString) - 1)
	else
		set @cTempString = @cString

	set @cString = replace(@cString, @cTempString + '&', '')

	while @nCounter < @nKeyNumber and @cString <> ''
	begin
		if charindex(@cPairDelimiter, @cString) > 0
			set @cTempString = substring(@cString, 1, charindex(@cPairDelimiter, @cString) - 1)
		else
			set @cTempString = @cString

		set @cString = replace(@cString, @cTempString, '')
		if left(@cString, 1) = '&'
			set @cString = substring(@cString, 2, 500)

		set @nCounter = @nCounter + 1
	end

	if @nCounter = @nKeyNumber and charindex('=', @cTempString) > 0
		return @cTempString

	return null
end
GO
