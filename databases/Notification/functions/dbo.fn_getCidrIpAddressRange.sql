/****** Object:  UserDefinedFunction [dbo].[fn_getCidrIpAddressRange]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_getCidrIpAddressRange](@cIpAddress varchar(15), @nMask int)
returns @result table
(
    lowRange    varchar(15) not null,
    highRange   varchar(15) not null,
    addressQty  bigint not null
)
as
begin

	declare @nBase       bigint  = cast(4294967295 as bigint)
	declare @nPower      bigint  = Power(2.0, 32.0 - @nMask) - 1
	declare @nLowRange   bigint  = dbo.fn_convertIPToLong(@cIpAddress) & (@nBase ^ @nPower)
	declare @nHighRange  bigint  = @nLowRange + @nPower

	insert @result
	select
		 lowRange   = dbo.fn_convertLongToIp(@nLowRange)
		,highRange  = dbo.fn_convertLongToIp(@nHighRange)
		,addressQty = convert(bigint, power(2.0, (32.0 - @nMask)))

	return
end
GO
