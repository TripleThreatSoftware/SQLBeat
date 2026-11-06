/****** Object:  UserDefinedFunction [dbo].[fn_convertLongToIp]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_convertLongToIp](@nIpLong bigint)
returns varchar(15)
as
begin
	declare
		 @cIpHex     varchar(8)
		,@cIpDotted  varchar(15)

	select
		 @cIpHex = substring(convert(varchar(30), master.dbo.fn_varbintohexstr(@nIpLong)), 11, 8)

	select
		@cIpDotted = convert(varchar(3), convert(int, (convert(varbinary, substring(@cIpHex, 1, 2), 2)))) + '.' +
					convert(varchar(3), convert(int, (convert(varbinary, substring(@cIpHex, 3, 2), 2)))) + '.' +
					convert(varchar(3), convert(int, (convert(varbinary, substring(@cIpHex, 5, 2), 2)))) + '.' +
					convert(varchar(3), convert(int, (convert(varbinary, substring(@cIpHex, 7, 2), 2))))


	return @cIpDotted
end
GO
