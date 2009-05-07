/****** Object:  UserDefinedFunction [dbo].[fn_checksum]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select dbo.fn_checksum('hello world')
-- select dbo.fn_checksum('hello world2')
create function [dbo].[fn_checksum](@cString varchar(max))
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
GO
