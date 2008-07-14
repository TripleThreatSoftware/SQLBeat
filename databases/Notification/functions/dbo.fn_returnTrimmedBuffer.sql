ALTER function [dbo].[fn_returnTrimmedBuffer] (@cBufferContents varchar(8000))
returns varchar(500)
as
begin
	declare @cReturnString varchar(500)
	declare @nTrimPosition int
--	declare @nTrimCounter int
--	declare @cPrepend varchar(50)

--	set @cBufferContents = ltrim(replace(@cBufferContents, char(9), ''))
	set @cBufferContents = rtrim(ltrim(replace(replace(replace(replace(replace(replace(@cBufferContents, char(9), ' '), char(13), ' '), char(10), ' '), ']', ''), '[', ''), 'dbo.', '')))

--	set @nTrimCounter = 0
--	set @cPrepend = '"' + left(@cBufferContents, 2) + '"'

	while left(@cBufferContents, 2) = '--'
		and (
			charindex(char(13), @cBufferContents) > 0
			or charindex(space(2), substring(@cBufferContents, 3, 8000)) > 0
			or charindex('--', substring(@cBufferContents, 3, 8000)) > 0
			)
	begin
		set @nTrimPosition = 9999
		if charindex(char(13), substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(char(13), substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(char(13), substring(@cBufferContents, 3, 8000))
		if charindex(space(2), substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(space(2), substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(space(2), substring(@cBufferContents, 3, 8000)) + 2
		if charindex('--', substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex('--', substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex('--', substring(@cBufferContents, 3, 8000)) + 2

		set @cBufferContents = ltrim(rtrim(substring(@cBufferContents, @nTrimPosition , 8000)))
--		set @nTrimCounter = @nTrimCounter + 1
	end

	if left(@cBufferContents, 2) = '/*'
		set @cBufferContents = substring(@cBufferContents, charindex('*/', @cBufferContents) + 2, 500)

	if (
			(patindex('%create%proc%', @cBufferContents) < patindex('%insert into%', @cBufferContents) or patindex('%insert into%', @cBufferContents) = 0)
			and (patindex('%create%proc%', @cBufferContents) < patindex('%select[ ]%from[ ]%', @cBufferContents) or patindex('%select[ ]%from[ ]%', @cBufferContents) = 0)
			and (patindex('%create%proc%', @cBufferContents) < patindex('%update[ ]%set[ ]%', @cBufferContents) or patindex('%update[ ]%set[ ]%', @cBufferContents) = 0)
			and patindex('%create%proc%', @cBufferContents) > 0
		)
		or (
			(patindex('%create%func%', @cBufferContents) < patindex('%insert into%', @cBufferContents) or patindex('%insert into%', @cBufferContents) = 0)
			and (patindex('%create%func%', @cBufferContents) < patindex('%select[ ]%from[ ]%', @cBufferContents) or patindex('%select[ ]%from[ ]%', @cBufferContents) = 0)
			and (patindex('%create%func%', @cBufferContents) < patindex('%update[ ]%set[ ]%', @cBufferContents) or patindex('%update[ ]%set[ ]%', @cBufferContents) = 0)
			and patindex('%create%func%', @cBufferContents) > 0
		)
	begin
		set @cBufferContents = replace(replace(replace(replace(replace(@cBufferContents, space(1), space(0)), char(9), space(0)), char(13), space(0)), char(10), space(0)), ascii(32), '')
		set @cBufferContents = replace(replace(replace(replace(@cBufferContents, 'createprocedure', '~~'), 'createproc', '~~'), 'createfunction', '~~'), 'createfunc', '~~')

		if charindex('~~', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, charindex('~~', @cBufferContents) + 2, 500)

		if charindex('(', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('(', @cBufferContents) - 1)
		if charindex('@', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('@', @cBufferContents) - 1)
		if charindex('asbegin', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('asbegin', @cBufferContents) - 1)
		else
			if charindex('asselect', @cBufferContents) > 0
				set @cBufferContents = left(@cBufferContents, charindex('asselect', @cBufferContents) - 1)
				else
					if charindex('AS', @cBufferContents) > 0 and charindex('begin', @cBufferContents) > 0
						set @cBufferContents = left(@cBufferContents, charindex('AS', @cBufferContents) - 1)

		set @cReturnString = left(@cBufferContents, 500)
	end
	else
		if left(@cBufferContents, 100) like '%insert into%'
		begin
			set @cBufferContents = replace(replace(replace(@cBufferContents, 'SELECT', '~~'), 'EXEC', '~~'), 'VALUES', '~~')

			if charindex('~~', @cBufferContents) >= 1
				set @cReturnString = left(@cBufferContents, charindex('~~', @cBufferContents) - 1)

			if left(@cReturnString, 1) = '('
				set @cReturnString = substring(@cReturnString, charindex('insert into', @cReturnString), 500)
		end
		else
		begin
			declare @cWhereClause varchar(8000)
			set @cWhereClause = ''

			if charindex('where', @cBufferContents) > 0
			begin
				set @cWhereClause = substring(@cBufferContents, charindex('WHERE', @cBufferContents), 500)
				set @cWhereClause = replace(replace(replace(@cWhereClause, char(13), '~~'), char(10), '~~'), char(9), '~~')
				set @cWhereClause = replace(@cWhereClause, ' and', '~~and')
				set @cWhereClause = replace(@cWhereClause, ' or', '~~or')

				declare @whereClause table (token varchar(1000))

				insert into @whereClause (token)
				select listItem from dbo.fn_makeTableFromList(@cWhereClause, '~~')

				update @whereClause set token = left(token, charindex('=', token)) + '= XXX' where charindex('=', token) > 0
				update @whereClause set token = left(token, charindex('in', token)) + 'in XXX' where token like ' in%(' and charindex('charindex', token) = 0
				update @whereClause set token = left(token, charindex('like', token)) + 'like XXX' where charindex('like', token) > 0

				set @cWhereClause = ''
				select @cWhereClause = @cWhereClause + token + space(1) from @whereClause
			end

			set @cReturnString = left(
				case
					when @cBufferContents like '%select[ ]%from[ ]%where[ ]%'
							and (charindex('where ', @cBufferContents) - charindex('from ', @cBufferContents) - 6) >= 0
						then 'SELECT ... ' +
							'FROM ' + substring(@cBufferContents, charindex('from ', @cBufferContents) + 5, charindex('where ', @cBufferContents) - charindex('from ', @cBufferContents) - 6) + ' ' +
							isnull(@cWhereClause, 'WHERE ...')
					when @cBufferContents like '%select[ ]%from[ ]%'
						then 'SELECT ... FROM ' + substring(@cBufferContents, charindex('from ', @cBufferContents) + 5, 500)
					when @cBufferContents like '%update[ ]%set[ ]%where[ ]%'
						then left(
							substring(@cBufferContents, charindex('update', @cBufferContents), 500), charindex('SET', substring(@cBufferContents, charindex('update', @cBufferContents), 500)) -1 ) + ' ' +
								'SET ... ' +
								isnull(@cWhereClause, 'WHERE ...')
					when @cBufferContents like '%update[ ]%set[ ]%'
						then left(substring(@cBufferContents, charindex('update', @cBufferContents), 500), charindex('SET', substring(@cBufferContents, charindex('update', @cBufferContents), 500)) -1 ) + ' SET ... '
					else @cBufferContents
					end, 500)

			if dbo.fn_occurs(space(1), @cReturnString) = 1 and left(@cReturnString, 4) <> 'exec'
				set @cReturnString = left(@cReturnString, charindex(space(1), @cReturnString))
		end

--	if charindex('"', @cReturnString) > 1
--		set @cReturnString = left(@cReturnString, charindex('"', @cReturnString) - 1)
--	if charindex('@', @cReturnString) > 1 and charindex('@@', @cReturnString) = 0
--		set @cReturnString = left(@cReturnString, charindex('@', @cReturnString) - 1)

--	set @cReturnString = convert(varchar(20), @nTrimCounter) + @cPrepend + @cReturnString

	return @cReturnString
end

-- select dbo.fn_returnTrimmedBuffer('create function fn_trjisdf(')
