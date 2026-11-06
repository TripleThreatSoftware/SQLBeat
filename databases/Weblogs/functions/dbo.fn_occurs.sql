/****** Object:  UserDefinedFunction [dbo].[fn_occurs]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_occurs] (@cStringToFind varchar(8000), @cSource varchar(8000))
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
-- select dbo.fn_occurs('agfgd', 'abag')
GO
