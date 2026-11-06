/****** Object:  UserDefinedFunction [dbo].[fn_returnUTCDate]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_returnUTCDate] (@dToday dateTime)
returns varchar(50)
as
begin
	--declare @dToday dateTime
	--set @dToday = dateAdd(hour, -5, getDate())

	return convert(varchar(4), datePart(year, @dToday)) +
		right('00' + convert(varchar(2), datePart(month, @dToday)), 2) +
		right('00' + convert(varchar(2), datePart(day, @dToday)), 2) +

		right('00' + convert(varchar(2), datePart(hour, @dToday)), 2) +
		right('00' + convert(varchar(2), datePart(minute, @dToday)), 2) +
		right('00' + convert(varchar(2), datePart(second, @dToday)), 2) +

		'.000000' +

		'-' + left(convert(varchar(2), dateDiff(hour, getDate(), getUTCDate())) + '000', 3)
end
GO
