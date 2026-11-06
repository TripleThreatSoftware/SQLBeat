/****** Object:  UserDefinedFunction [dbo].[fn_UTC_to_DST]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_UTC_to_DST]
(
    @UTC datetime,
    @StandardOffset int
)
RETURNS datetime
AS
BEGIN

    declare
        @DST datetime,
        @SSM datetime, -- Second Sunday in March
        @FSN datetime  -- First Sunday in November

    -- get DST Range
    set @SSM = datename(year,@UTC) + '0314'
    set @SSM = dateadd(hour,2,dateadd(day,datepart(dw,@SSM)*-1+1,@SSM))
    set @FSN = datename(year,@UTC) + '1107'
    set @FSN = dateadd(second,-1,dateadd(hour,2,dateadd(day,datepart(dw,@FSN)*-1+1,@FSN)))

    -- add an hour to @StandardOffset if @UTC is in DST range
    if @UTC between @SSM and @FSN
        set @StandardOffset = @StandardOffset + 1

    -- convert to DST
    set @DST = dateadd(hour,@StandardOffset,@UTC)

    -- return converted datetime
    return @DST

END
GO
