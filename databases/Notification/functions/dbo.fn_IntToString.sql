CREATE function [fn_IntToString] (@nNumber bigint)
returns varchar(100)
as
begin
	declare @cReturnString varchar(100)
	set @cReturnString = reverse(substring(reverse(convert(varchar(20), convert(money, @nNumber), 1)), 4, 20))

	return @cReturnString

end
-- select dbo.fn_IntToString(1234567)



GO
