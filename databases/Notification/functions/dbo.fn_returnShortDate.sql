/****** Object:  UserDefinedFunction [dbo].[fn_returnShortDate]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_returnShortDate] (@dToday dateTime)
returns varchar(14)
as
begin
	declare @cReturnString varchar(14)
	set @cReturnString = ''

	if @dToday is not null and year(@dToday) > 1900
		set @cReturnString =
			right('00' + convert(varchar(2), datepart(month, @dToday)), 2) + '-' +
			right('00' + convert(varchar(2), datepart(day, @dToday)), 2) + '-' +
			right(convert(varchar(4), datepart(year, @dToday)), 2) + ' ' +
			right('00' + convert(varchar(2), datepart(hour, @dToday)), 2) + ':' +
			right('00' + convert(varchar(2), datepart(minute, @dToday)), 2)

	return @cReturnString
end
GO
