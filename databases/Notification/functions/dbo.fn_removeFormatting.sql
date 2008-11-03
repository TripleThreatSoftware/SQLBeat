create function dbo.fn_removeFormatting(@cString varchar(8000))
returns varchar(8000)
as
begin
	declare @cReturnString varchar(8000)

	set @cReturnString = replace(replace(replace(@cString, space(1), space(0)), char(9), space(0)), char(13), space(0))

	return @cReturnString
end



GO
