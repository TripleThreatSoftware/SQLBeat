--= select dbo.fn_returnTrimmedPlanText('(@nUkeyProduct int,@cSessionID nvarchar(24),@cMachineID nvarchar(24),@nUkeyWebsite int)exec pr_returnProductImages @cSessionID, @cMachineID, @nUkeyProduct, 0')

create function fn_returnTrimmedPlanText (@cSQLString varchar(8000))
returns varchar(1000)
as
begin
	declare @cReturnString varchar(1000)
	declare @nCounter int
	declare @nDepth int

	if left(@cSQLString, 1) <> '('
	begin
		set @cReturnString = left(@cSQLString, 1000)
		return @cReturnString
	end

	set @nCounter = 2
	set @nDepth = 1

	while @nCounter < len(@cSQLString) and @nDepth >= 1
	begin
		if substring(@cSQLString, @nCounter, 1) = '('
			set @nDepth = @nDepth + 1

		if substring(@cSQLString, @nCounter, 1) = ')'
			set @nDepth = @nDepth - 1

		set @nCounter = @nCounter + 1
	end

	set @cReturnString = replace(replace(substring(@cSQLString, @nCounter, 1000), 'exec ', ''), 'execute ', '')

	if charindex(' ', @cReturnString) > 0
		set @cReturnString = left(@cReturnString, charindex(' ', @cReturnString))

	return @cReturnString
end
