CREATE function [fn_dateNoTime] (@dInputDate datetime)
returns datetime
as
BEGIN
	-- takes a datetime and cuts off the time part
	return convert(varchar(20),@dInputDate,101)
END



GO
