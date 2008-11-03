create function [fn_encodeForGoogleCharts_simple] (@nNumber int)
returns varchar(1)
as
begin
	declare @cReturnValue varchar(1)

	set @cReturnValue = case
		when @nNumber >= 0 and @nNumber <= 25
			then char(@nNumber + 65)
		when @nNumber >= 26 and @nNumber <= 51
			then char(@nNumber + 97 - 26)
		when @nNumber >= 52 and @nNumber <= 61
			then char(@nNumber + 48 - 52)
		when @nNumber is null
			then '_'
		else '_'
		end

	return @cReturnValue
end



GO
