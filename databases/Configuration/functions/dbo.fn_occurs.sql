/****** Object:  UserDefinedFunction [dbo].[fn_occurs]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_occurs] (@cStringToFind varchar(500), @cSource varchar(500))
returns int
as
begin
	declare @nOccurs int
	declare @nCounter int
	declare @nStringLength int
	set @nCounter = 1
	set @nOccurs = 0
	set @nStringLength = len(@cStringToFind)
	if @cStringToFind = space(1)
		set @nStringLength = 1

	while (@nCounter - 1 + @nStringLength) < (len(@cSource) + 1)
	begin
		if substring(@cSource, @nCounter, @nStringLength) = @cStringToFind
			set @nOccurs = @nOccurs + 1

		set @nCounter = @nCounter + 1
	end

	return @nOccurs
end
-- select dbo.fn_occurs(' ', 'test test')
GO
