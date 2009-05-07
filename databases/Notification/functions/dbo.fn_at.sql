/****** Object:  UserDefinedFunction [dbo].[fn_at]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE function [dbo].[fn_at] (@cSourceString varchar(2000), @cStringToFind varchar(500), @nInstance int)
returns int
as
begin
	declare @nCounter int
	declare @nLastFound int
	declare @nThisFound int

	set @nCounter = 1
	set @nLastFound = charindex(@cStringToFind, @cSourceString)

	while not (@nCounter = @nInstance)
	begin
		set @nThisFound = charindex(@cStringToFind, @cSourceString, @nLastFound + 1)

		if @nThisFound > 0
		begin
			set @nLastFound = @nThisFound
			set @nCounter = @nCounter + 1
		end
		else
			break
	end

	if @nCounter = @nInstance
		return @nLastFound

	return 0
end
GO
