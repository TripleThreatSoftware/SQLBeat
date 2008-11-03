CREATE function [fn_hex_to_char] (@x varbinary(100), @l int)
	returns varchar(200)
as
begin
	-- This code from Gregory A. Larsen
	-- http://www.databasejournal.com/features/mssql/article.php/3500276

	declare @i varbinary(10)
	declare @digits char(16)
	set @digits = '0123456789ABCDEF'
	declare @s varchar(100)
	declare @h varchar(100)
	declare @j int
	set @j = 0
	set @h = ''

	while @j < @l
	begin
		set @j= @j + 1
		set @i = substring(cast(@x as varbinary(100)), @j, 1)
		set @s = cast(substring(@digits,@i%16+1,1) as char(1))
		set @i = @i/16
		set @s = cast(substring(@digits,@i%16+1,1) as char(1)) + @s
		set @h = @h + @s
	end
	return(@h)
end



GO
