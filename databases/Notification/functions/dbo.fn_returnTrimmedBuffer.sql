SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[fn_returnTrimmedBuffer] (@cBufferContents varchar(8000))
returns varchar(500)
as
begin
	declare @cReturnString varchar(500)
	declare @nTrimPosition int
	declare @cWorkingBuffer varchar(8000)

	-- trim comments
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

	set @cBufferContents = rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(@cBufferContents, char(9), ' '), char(13), ' '), char(10), ' '), ']', ''), '[', ''), 'dbo.', ''), '~', '')))

	set @cBufferContents =
		replace(replace(
				@cBufferContents,
				' S' + space(1) + 'ET', ' SET'),
				' SE' + space(1) + 'T', ' SET')

	set @cBufferContents =
		replace(replace(replace(
				@cBufferContents,
				'W' + space(1) + 'ITH', 'WITH'),
				'WI' + space(1) + 'TH', 'WITH'),
				'WIT' + space(1) + 'H', 'WITH')

	set @cBufferContents =
		replace(replace(replace(replace(replace(
				@cBufferContents,
				'U' + space(1) + 'PDATE', 'UPDATE'),
				'UP' + space(1) + 'DATE', 'UPDATE'),
				'UPD' + space(1) + 'ATE', 'UPDATE'),
				'UPDA' + space(1) + 'TE', 'UPDATE'),
				'UPDAT' + space(1) + 'E', 'UPDATE')

	set @cBufferContents =
		replace(replace(replace(replace(replace(
				@cBufferContents,
				'S' + space(1) + 'ELECT', 'SELECT'),
				'SE' + space(1) + 'LECT', 'SELECT'),
				'SEL' + space(1) + 'ECT', 'SELECT'),
				'SELE' + space(1) + 'CT', 'SELECT'),
				'SELEC' + space(1) + 'T', 'SELECT')

	set @cBufferContents =
		replace(replace(replace(replace(replace(
				@cBufferContents,
				'C' + space(1) + 'REATE', 'CREATE'),
				'CR' + space(1) + 'EATE', 'CREATE'),
				'CRE' + space(1) + 'ATE', 'CREATE'),
				'CREA' + space(1) + 'TE', 'CREATE'),
				'CREAT' + space(1) + 'E', 'CREATE')

	set @cBufferContents =
		replace(replace(replace(replace(replace(
				@cBufferContents,
				'I' + space(1) + 'NSERT', 'INSERT'),
				'IN' + space(1) + 'SERT', 'INSERT'),
				'INS' + space(1) + 'ERT', 'INSERT'),
				'INSE' + space(1) + 'RT', 'INSERT'),
				'INSER' + space(1) + 'T', 'INSERT')

	set @cBufferContents =
		replace(replace(replace(replace(
				@cBufferContents,
				'W' + space(1) + 'HERE', 'WHERE'),
				'WH' + space(1) + 'ERE', 'WHERE'),
				'WHE' + space(1) + 'RE', 'WHERE'),
				'WHER' + space(1) + 'E', 'WHERE')

	set @cBufferContents =
		replace(replace(replace(replace(replace(replace(replace(replace(
				@cBufferContents,
				'P' + space(1) + 'ROCEDURE', 'PROCEDURE'),
				'PR' + space(1) + 'OCEDURE', 'PROCEDURE'),
				'PRO' + space(1) + 'CEDURE', 'PROCEDURE'),
				'PROC' + space(1) + 'EDURE', 'PROCEDURE'),
				'PROCE' + space(1) + 'DURE', 'PROCEDURE'),
				'PROCED' + space(1) + 'URE', 'PROCEDURE'),
				'PROCEDU' + space(1) + 'RE', 'PROCEDURE'),
				'PROCEDUR' + space(1) + 'E', 'PROCEDURE')

	set @cBufferContents =
		replace(replace(replace(replace(replace(replace(replace(
				@cBufferContents,
				'F' + space(1) + 'UNCTION', 'FUNCTION'),
				'FU' + space(1) + 'NCTION', 'FUNCTION'),
				'FUN' + space(1) + 'CTION', 'FUNCTION'),
				'FUNC' + space(1) + 'TION', 'FUNCTION'),
				'FUNCT' + space(1) + 'ION', 'FUNCTION'),
				'FUNCTI' + space(1) + 'ON', 'FUNCTION'),
				'FUNCTIO' + space(1) + 'N', 'FUNCTION')

	set @cWorkingBuffer = replace(@cBufferContents, space(1), space(0))

	if left(@cBufferContents, 2) = '/*'
		set @cBufferContents = substring(@cBufferContents, charindex('*/', @cBufferContents) + 2, 500)

	if (
			(patindex('%createprocedure%', @cWorkingBuffer) < patindex('%insertinto%', @cWorkingBuffer) or patindex('%insertinto%', @cWorkingBuffer) = 0)
			and (patindex('%createprocedure%', @cWorkingBuffer) < patindex('%select%from%', @cWorkingBuffer) or patindex('%select%from%', @cWorkingBuffer) = 0)
			and (patindex('%createprocedure%', @cWorkingBuffer) < patindex('%update%set%', @cWorkingBuffer) or patindex('%update%set%', @cWorkingBuffer) = 0)
			and patindex('%createprocedure%', @cWorkingBuffer) > 0
		)
		or (
			(patindex('%createfunction%', @cWorkingBuffer) < patindex('%insertinto%', @cWorkingBuffer) or patindex('%insertinto%', @cWorkingBuffer) = 0)
			and (patindex('%createfunction%', @cWorkingBuffer) < patindex('%select%from%', @cWorkingBuffer) or patindex('%select%from%', @cWorkingBuffer) = 0)
			and (patindex('%createfunction%', @cWorkingBuffer) < patindex('%update%set%', @cWorkingBuffer) or patindex('%update%set%', @cWorkingBuffer) = 0)
			and patindex('%createfunction%', @cWorkingBuffer) > 0
		)
	begin
		set @cBufferContents = replace(@cBufferContents, 'with ', '$$')
		set @cBufferContents = replace(replace(replace(replace(replace(@cBufferContents, space(1), space(0)), char(9), space(0)), char(13), space(0)), char(10), space(0)), ascii(32), '')
		set @cBufferContents = replace(replace(replace(replace(@cBufferContents, 'createprocedure', '~~'), 'createproc', '~~'), 'createfunction', '~~'), 'createfunc', '~~')

		if charindex('~~', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, charindex('~~', @cBufferContents) + 2, 500)

		if charindex('$$', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, 1, charindex('$$', @cBufferContents) - 1)

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
	begin
		if left(@cBufferContents, 1) = '(' and charindex('))', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, charindex('))', @cBufferContents) + 2, 8000)

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
	end

--	if charindex('"', @cReturnString) > 1
--		set @cReturnString = left(@cReturnString, charindex('"', @cReturnString) - 1)
--	if charindex('@', @cReturnString) > 1 and charindex('@@', @cReturnString) = 0
--		set @cReturnString = left(@cReturnString, charindex('@', @cReturnString) - 1)

--	set @cReturnString = convert(varchar(20), @nTrimCounter) + @cPrepend + @cReturnString

	if left(@cReturnString, 4) = 'dbo.'
		set @cReturnString = substring(@cReturnString, 5, 500)

	if @cReturnString in ('begin', 'select', '(', 'begin tran')
		set @cReturnString = @cBufferContents

	return @cReturnString
end

-- select dbo.fn_returnTrimmedBuffer('create function fn_trjisdf(')
