/****** Object:  UserDefinedFunction [dbo].[fn_noVowels]    Script Date: 12/04/2009 18:54:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fn_noVowels] (@cString varchar(500))
returns varchar(500)
as
begin
	return replace(replace(replace(replace(replace(@cString, 'a', ''), 'e', ''), 'i', ''), 'o', ''), 'u', '')
end
GO
