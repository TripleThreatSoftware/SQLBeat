IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'sqlnotification')
CREATE USER [sqlnotification] FOR LOGIN [sqlnotification] WITH DEFAULT_SCHEMA=[dbo]
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_returnDigits]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE         function [fn_returnDigits](@cSomeString varchar(50), @lStopAtFirstNonNumber bit = 0)
returns bigInt
as
begin

	declare @nLength int
	declare @nCounter int
	declare @cReturnValue varchar(50)
	declare @nReturnValue bigint
	declare @cCharacter varchar(1)

	set @cReturnValue = ''''
	set @cSomeString = rtrim(ltrim(@cSomeString))

	if @cSomeString is not null
	begin
		set @nLength = len(@cSomeString)
		set @nCounter = 1
		while @nCounter <= @nLength
		begin
			set @cCharacter = substring(@cSomeString, @nCounter, 1)
			if @cCharacter in (''1'', ''2'', ''3'', ''4'', ''5'', ''6'', ''7'', ''8'', ''9'', ''0'')
				set @cReturnValue = rtrim(@cReturnValue) + @cCharacter
			else
			begin
				if @lStopAtFirstNonNumber = 1 and len(@cReturnValue) > 0
					break
			end

			set @nCounter = @nCounter + 1
		end
	end

	if isnumeric(@cReturnValue) = 1 and len(@cReturnValue) < 15 -- and @cReturnValue < ''9223372036854775807''
		set @nReturnValue = convert(bigint, @cReturnValue)
	else
		set @nReturnValue = 0

	return @nReturnValue
end
'
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_returnKeyValue]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_returnKeyValue] (@cString varchar(500), @cKey varchar(100))
returns varchar(200)
as
begin
	if charindex(@cKey, @cString) = 0 or charindex(''='', @cString) = 0 or charindex('';'', @cString) = 0
		return ''''

	declare @cValue varchar(200)

	if len(@cString) - charindex(@cKey, @cString) <= 0
		return ''''
	set @cString = right(@cString, len(@cString) - charindex(@cKey, @cString) + 1)

	if len(@cString) - charindex(''='', @cString) <= 0
		return ''''
	set @cString = right(@cString, len(@cString) - charindex(''='', @cString))

	if charindex('';'', @cString)-1 <= 0
		return @cString
	set @cValue = left(@cString, charindex('';'', @cString)-1)

	return @cValue
end
'
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_returnKeyValuePair]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_returnKeyValuePair] (@cString varchar(500), @nKeyNumber int, @cPairDelimiter varchar(10))
returns varchar(200)
as
begin
	declare @nCounter int
	declare @cTempString varchar(500)
	set @nCounter = 1

	-- if there''s more than one key/value pair in the string
	if charindex(@cPairDelimiter, @cString) > 0
		set @cTempString = substring(@cString, 1, charindex(@cPairDelimiter, @cString) - 1)
	else
		set @cTempString = @cString

	set @cString = replace(@cString, @cTempString + ''&'', '''')

	while @nCounter < @nKeyNumber and @cString <> ''''
	begin
		if charindex(@cPairDelimiter, @cString) > 0
			set @cTempString = substring(@cString, 1, charindex(@cPairDelimiter, @cString) - 1)
		else
			set @cTempString = @cString

		set @cString = replace(@cString, @cTempString, '''')
		if left(@cString, 1) = ''&''
			set @cString = substring(@cString, 2, 500)

		set @nCounter = @nCounter + 1
	end

	if @nCounter = @nKeyNumber and charindex(''='', @cTempString) > 0
		return @cTempString

	return null
end
'
END
GO
