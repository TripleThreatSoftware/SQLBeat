CREATE         function [fn_returnDigits](@cSomeString varchar(50), @lStopAtFirstNonNumber bit = 0)
returns bigInt
as
begin

	declare @nLength int
	declare @nCounter int
	declare @cReturnValue varchar(50)
	declare @nReturnValue bigint
	declare @cCharacter varchar(1)

	set @cReturnValue = ''
	set @cSomeString = rtrim(ltrim(@cSomeString))

	if @cSomeString is not null
	begin
		set @nLength = len(@cSomeString)
		set @nCounter = 1
		while @nCounter <= @nLength
		begin
			set @cCharacter = substring(@cSomeString, @nCounter, 1)
			if @cCharacter in ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0')
				set @cReturnValue = rtrim(@cReturnValue) + @cCharacter
			else
			begin
				if @lStopAtFirstNonNumber = 1 and len(@cReturnValue) > 0
					break
			end

			set @nCounter = @nCounter + 1
		end
	end

	if isnumeric(@cReturnValue) = 1 and len(@cReturnValue) < 15 -- and @cReturnValue < '9223372036854775807'
		set @nReturnValue = convert(bigint, @cReturnValue)
	else
		set @nReturnValue = 0

	return @nReturnValue
end



GO
