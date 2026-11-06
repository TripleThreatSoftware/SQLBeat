/****** Object:  UserDefinedFunction [dbo].[fn_noPunctuation]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_noPunctuation] (@cString varchar(500))
returns varchar(500)
as
begin
	return replace(replace(replace(replace(replace(replace(replace(
		@cString,
		'.', ''), '-', ' '), '/', ' '), '&', ''), ',', ''), ' ', ''), '+', '')
end
GO
