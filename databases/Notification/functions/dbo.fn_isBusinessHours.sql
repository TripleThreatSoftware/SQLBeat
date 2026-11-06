/****** Object:  UserDefinedFunction [dbo].[fn_isBusinessHours]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  function [dbo].[fn_isBusinessHours] ()
returns bit
as
begin
	-- We need to know if it's business hours so we can queue the low priority alerts
	declare @bIsOffHours bit
	declare @dToday dateTime

	set @dToday = (select ymd from v_getDate)

	set @bIsOffHours = 0
	if datePart(hour, @dToday) >= 17 or datePart(hour, @dToday) < 8 or dateName(weekDay, @dToday) in ('Saturday', 'Sunday')
		set @bIsOffHours = 1

	if right(convert(varchar(10), @dToday, 120), 5) in ('01-01', '12-24', '12-25', '12-26', '07-04') -- , '12-31'  grrrrrr
		set @bIsOffHours = 1

	if @bIsOffHours = 1
		return 0
	else
		return 1

	return 1
end
GO
