/****** Object:  UserDefinedFunction [dbo].[fn_convertUTCDateString]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fn_convertUTCDateString] (@cDateString varchar(100))
returns dateTime
as
begin
--	declare @cDateString varchar(100)
--	set @cDateString = '20100519131259.000000-240'
	declare @dReturnDate dateTime

	if isdate(left(@cDateString, 4) + '-' +
		substring(@cDateString, 5, 2) + '-' +
		substring(@cDateString, 7, 2) + ' ' +
		substring(@cDateString, 9, 2) + ':' +
		substring(@cDateString, 11, 2) + ':' +
		substring(@cDateString, 13, 2)
		) = 1
	begin
		set @dReturnDate = convert(dateTime,
			left(@cDateString, 4) + '-' +
			substring(@cDateString, 5, 2) + '-' +
			substring(@cDateString, 7, 2) + ' ' +
			substring(@cDateString, 9, 2) + ':' +
			substring(@cDateString, 11, 2) + ':' +
			substring(@cDateString, 13, 2)
			)
	end
	return @dReturnDate
end
GO
