/****** Object:  UserDefinedFunction [dbo].[fn_convertIPToLong]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_convertIPToLong](@cIP varchar(15))
returns bigint
as
begin
    declare @nLong bigint
    set @nLong = CONVERT(bigint, PARSENAME(@cIP, 4)) * 256 * 256 * 256 +
        CONVERT(bigint, PARSENAME(@cIP, 3)) * 256 * 256 +
        CONVERT(bigint, PARSENAME(@cIP, 2)) * 256 +
        CONVERT(bigint, PARSENAME(@cIP, 1))

    return (@nLong)
end
GO
