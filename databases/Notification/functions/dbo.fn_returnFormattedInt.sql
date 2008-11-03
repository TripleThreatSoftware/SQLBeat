CREATE function [fn_returnFormattedInt] (@nNumber bigint)
returns varchar(50)
as
begin
	declare @cReturnString varchar(50)

	set @cReturnString = convert(varchar(50), convert(money, @nNumber), 1)
	set @cReturnString = left(@cReturnString, len(@cReturnString) - 3)

	return @cReturnString
end
-- select dbo.fn_returnFormattedInt(12345)



GO
