IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_returnTrimmedBuffer]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'--select dbo.fn_returnTrimmedBuffer(''          -- select top 100 * from pingResults order by ymd desc  -- exec pr_pingServer ''''sqlserver\instance1''''  -- update pingResults set sqlPingResults = pingResults where sqlPingResults is null  -- alter table pingResults drop column pingResults  CREATE           procedure [dbo].[pr_pingServer] (@cServerName varchar(100))  as  begin   declare @cServerNamePart varchar(100)   declare @cInstanceNamePart varchar(100)   declare @cCommandline varchar(200)   declare @cFriendlyName varchar(200)   declare @nTimesUnavailable int   declare @cThisSubject varchar(300)   declare @cThisMessage varchar(2000)   declare @bPingServer bit   declare @bIsBusinessHours bit   declare @nOffHoursPriority int     declare @cRouterMessage varchar(2000)   declare @cServerMessage varchar(2000)   declare @cSQLMessage varchar(2000)     declare @bIsRouterPingable bit   declare @bIsServerPingable bit   declare @bIsSQLPingable bit   declare @bIsEnabled bit     declare @bServiceCheck bit     '')

CREATE function [fn_returnTrimmedBuffer] (@cBufferContents varchar(8000))
returns varchar(500)
as
begin
	declare @cReturnString varchar(500)
	declare @nTrimPosition int
--	declare @nTrimCounter int
--	declare @cPrepend varchar(50)

--	set @cBufferContents = ltrim(replace(@cBufferContents, char(9), ''''))
	set @cBufferContents = rtrim(ltrim(replace(replace(replace(replace(replace(replace(@cBufferContents, char(9), '' ''), char(13), '' ''), char(10), '' ''), '']'', ''''), ''['', ''''), ''dbo.'', '''')))

--	set @nTrimCounter = 0
--	set @cPrepend = ''"'' + left(@cBufferContents, 2) + ''"''

	while left(@cBufferContents, 2) = ''--''
		and (
			charindex(char(13), @cBufferContents) > 0
			or charindex(space(2), substring(@cBufferContents, 3, 8000)) > 0
			or charindex(''--'', substring(@cBufferContents, 3, 8000)) > 0
			)
	begin
		set @nTrimPosition = 9999
		if charindex(char(13), substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(char(13), substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(char(13), substring(@cBufferContents, 3, 8000))
		if charindex(space(2), substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(space(2), substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(space(2), substring(@cBufferContents, 3, 8000)) + 2
		if charindex(''--'', substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(''--'', substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(''--'', substring(@cBufferContents, 3, 8000)) + 2

		set @cBufferContents = ltrim(rtrim(substring(@cBufferContents, @nTrimPosition , 8000)))
--		set @nTrimCounter = @nTrimCounter + 1
	end

	if left(@cBufferContents, 2) = ''/*''
		set @cBufferContents = substring(@cBufferContents, charindex(''*/'', @cBufferContents) + 2, 500)

	if (
			(patindex(''%create%proc%'', @cBufferContents) < patindex(''%insert into%'', @cBufferContents) or patindex(''%insert into%'', @cBufferContents) = 0)
			and (patindex(''%create%proc%'', @cBufferContents) < patindex(''%select[ ]%from[ ]%'', @cBufferContents) or patindex(''%select[ ]%from[ ]%'', @cBufferContents) = 0)
			and (patindex(''%create%proc%'', @cBufferContents) < patindex(''%update[ ]%set[ ]%'', @cBufferContents) or patindex(''%update[ ]%set[ ]%'', @cBufferContents) = 0)
			and patindex(''%create%proc%'', @cBufferContents) > 0
		)
		or (
			(patindex(''%create%func%'', @cBufferContents) < patindex(''%insert into%'', @cBufferContents) or patindex(''%insert into%'', @cBufferContents) = 0)
			and (patindex(''%create%func%'', @cBufferContents) < patindex(''%select[ ]%from[ ]%'', @cBufferContents) or patindex(''%select[ ]%from[ ]%'', @cBufferContents) = 0)
			and (patindex(''%create%func%'', @cBufferContents) < patindex(''%update[ ]%set[ ]%'', @cBufferContents) or patindex(''%update[ ]%set[ ]%'', @cBufferContents) = 0)
			and patindex(''%create%func%'', @cBufferContents) > 0
		)
	begin
		set @cBufferContents = replace(replace(replace(replace(replace(@cBufferContents, space(1), space(0)), char(9), space(0)), char(13), space(0)), char(10), space(0)), ascii(32), '''')
		set @cBufferContents = replace(replace(replace(replace(@cBufferContents, ''createprocedure'', ''~~''), ''createproc'', ''~~''), ''createfunction'', ''~~''), ''createfunc'', ''~~'')

		if charindex(''~~'', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, charindex(''~~'', @cBufferContents) + 2, 500)

		if charindex(''('', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex(''('', @cBufferContents) - 1)
		if charindex(''@'', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex(''@'', @cBufferContents) - 1)
		if charindex(''asbegin'', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex(''asbegin'', @cBufferContents) - 1)
		else
			if charindex(''asselect'', @cBufferContents) > 0
				set @cBufferContents = left(@cBufferContents, charindex(''asselect'', @cBufferContents) - 1)
				else
					if charindex(''AS'', @cBufferContents) > 0 and charindex(''begin'', @cBufferContents) > 0
						set @cBufferContents = left(@cBufferContents, charindex(''AS'', @cBufferContents) - 1)

		set @cReturnString = left(@cBufferContents, 500)
	end
	else
		if left(@cBufferContents, 100) like ''%insert into%''
		begin
			set @cBufferContents = replace(replace(replace(@cBufferContents, ''SELECT'', ''~~''), ''EXEC'', ''~~''), ''VALUES'', ''~~'')

			if charindex(''~~'', @cBufferContents) >= 1
				set @cReturnString = left(@cBufferContents, charindex(''~~'', @cBufferContents) - 1)

			if left(@cReturnString, 1) = ''(''
				set @cReturnString = substring(@cReturnString, charindex(''insert into'', @cReturnString), 500)
		end
		else
		begin
			set @cReturnString = left(
				case
					when @cBufferContents like ''%select[ ]%from[ ]%where[ ]%''
							and (charindex(''where '', @cBufferContents) - charindex(''from '', @cBufferContents) - 6) >= 0
						then ''SELECT ... FROM '' + substring(@cBufferContents, charindex(''from '', @cBufferContents) + 5, charindex(''where '', @cBufferContents) - charindex(''from '', @cBufferContents) - 6) + '' WHERE ...''
					when @cBufferContents like ''%select[ ]%from[ ]%''
						then ''SELECT ... FROM '' + substring(@cBufferContents, charindex(''from '', @cBufferContents) + 5, 100)

					when @cBufferContents like ''%update[ ]%set[ ]%where[ ]%''
						then left(substring(@cBufferContents, charindex(''update'', @cBufferContents), 500), charindex(''SET'', substring(@cBufferContents, charindex(''update'', @cBufferContents), 500)) -1 ) + '' SET ... WHERE ...''-- + substring(@cBufferContents, charindex(''WHERE'', @cBufferContents), 500)
					when @cBufferContents like ''%update[ ]%set[ ]%''
						then left(substring(@cBufferContents, charindex(''update'', @cBufferContents), 500), charindex(''SET'', substring(@cBufferContents, charindex(''update'', @cBufferContents), 500)) -1 ) + '' SET ... ''
					else @cBufferContents
					end, 500)

			if dbo.fn_occurs(space(1), @cReturnString) = 1 and left(@cReturnString, 4) <> ''exec''
				set @cReturnString = left(@cReturnString, charindex(space(1), @cReturnString))
		end

--	if charindex(''"'', @cReturnString) > 1
--		set @cReturnString = left(@cReturnString, charindex(''"'', @cReturnString) - 1)
	if charindex(''@'', @cReturnString) > 1 and charindex(''@@'', @cReturnString) = 0
		set @cReturnString = left(@cReturnString, charindex(''@'', @cReturnString) - 1)

--	set @cReturnString = convert(varchar(20), @nTrimCounter) + @cPrepend + @cReturnString

	return @cReturnString
end

-- select dbo.fn_returnTrimmedBuffer(''create function fn_trjisdf('')
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_returnListItem]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE  function [fn_returnListItem] (@cList varchar(8000), @nItemNumber int, @cDelimiter varchar(5))
returns varchar(8000)
as
begin
	declare @cString varchar(8000)
	declare @nCurrentItem int
	declare @cResults varchar(8000)

	set @nCurrentItem = 0
	set @cResults = ''''

	while len(@cList) > 0
	begin
		-- skip if the first chars are the delimiter
		if left(@cList, len(@cDelimiter)) = @cDelimiter
			set @cList = right(@cList, len(@cList) - len(@cDelimiter))

		if charindex(@cDelimiter, @cList) > 0
		begin
			set @cString = left(@cList, charindex(@cDelimiter, @cList) - 1)
			set @cList = substring(@cList, charindex(@cDelimiter, @cList)+len(@cDelimiter), 8000)

			if charindex(''"'', @cString) > 0
			begin
				if charindex(@cDelimiter, @cList) = 0 and dbo.fn_occurs(''"'', @cString) = 1
				begin
					set @cString = @cString + @cDelimiter + @cList
					set @cList = ''''
				end
				else
				begin
					while dbo.fn_occurs(''"'', @cString) % 2 <> 0 and charindex(@cDelimiter, @cList) > 0
					begin
						set @cString = @cString + @cDelimiter + left(@cList, charindex(@cDelimiter, @cList) - 1)
						set @cList = substring(@cList, charindex(@cDelimiter, @cList)+len(@cDelimiter), 8000)
					end
				end
			end
		end
		else
		begin
			set @cString = @cList
			set @cList = ''''
		end

		set @nCurrentItem = @nCurrentItem + 1
		if @nCurrentItem = @nItemNumber
		begin
			set @cResults = rtrim(ltrim(@cString))
			return @cResults
		end
	end

	return @cResults
end

-- select dbo.fn_returnListItem(''transactionSet periodID="1" periodname="SHIFT" longId="2006-10-21" shortId="039" site="RT053"'', 6, '' '')
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
