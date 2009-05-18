/****** Object:  UserDefinedFunction [dbo].[fn_returnRunStamp]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fn_returnRunStamp] (@dToday dateTime)
returns bigint
as
begin
	declare @nRunStamp bigint

	set @nRunStamp = convert(bigint,
			convert(varchar(4), datePart(year, @dToday)) +
			dbo.fn_padl(convert(varchar(2), datePart(month, @dToday)), 2, '0') +
			dbo.fn_padl(convert(varchar(2), datePart(day, @dToday)), 2, '0') +
			dbo.fn_padl(convert(varchar(2), datePart(hour, @dToday)), 2, '0') +
			dbo.fn_padl(convert(varchar(2), datePart(minute, @dToday)), 2, '0') +
			dbo.fn_padl(convert(varchar(2), datePart(second, @dToday)), 2, '0') +
			dbo.fn_padl(convert(varchar(3), datePart(millisecond, @dToday)), 3, '0')
		)

	return @nRunStamp
end
GO
