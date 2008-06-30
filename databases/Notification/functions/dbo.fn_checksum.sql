use [notification]
go

-- select dbo.fn_checksum('hello world')
-- select dbo.fn_checksum('hello world2')
create function fn_checksum(@cString varchar(max))
returns bigint
as
begin
	declare @nResults bigint
	declare @nCounter int
	declare @cThisCharacter varchar(1)
	set @nResults = 0
	set @nCounter = 1

	while @nCounter <= len(@cString)
	begin
		set @cThisCharacter = substring(@cString, @nCounter, 1)

		if @cThisCharacter not in (char(13), char(10), space(1))
			set @nResults = @nResults + ascii(@cThisCharacter)

		set @nCounter = @nCounter + 1
	end

	return @nResults
end
