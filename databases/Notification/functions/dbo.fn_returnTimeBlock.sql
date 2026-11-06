/****** Object:  UserDefinedFunction [dbo].[fn_returnTimeBlock]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fn_returnTimeBlock] (@dRightNow dateTime)
returns dateTime
as
begin

	declare @dReturn dateTime

	set @dReturn = convert(dateTime,
		left(convert(varchar(20), @dRightNow, 120), 14) +
		convert(varchar(20), convert(int, datePart(minute, @dRightNow) / 15) * 15) +
		'.000'
		)

	return @dReturn

end
GO
