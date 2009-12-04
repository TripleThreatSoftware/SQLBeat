/****** Object:  UserDefinedFunction [dbo].[fn_occurs]    Script Date: 12/04/2009 18:54:11 ******/
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
	set @nCounter = 1
	set @nOccurs = 0

	while (@nCounter - 1 + len(@cStringToFind)) < (len(@cSource) + 1)
	begin
		if substring(@cSource, @nCounter, len(@cStringToFind)) = @cStringToFind
			set @nOccurs = @nOccurs + 1

		set @nCounter = @nCounter + 1
	end

	return @nOccurs
end
GO
