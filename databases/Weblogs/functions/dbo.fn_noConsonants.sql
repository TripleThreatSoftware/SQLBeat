/****** Object:  UserDefinedFunction [dbo].[fn_noConsonants]    Script Date: 12/04/2009 18:54:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fn_noConsonants] (@cString varchar(500))
returns varchar(500)
as
begin
	return replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
		@cString,
		'b', ''), 'c', ''), 'd', ''), 'f', ''), 'g', ''), 'h', ''), 'j', ''), 'k', ''), 'l', ''), 'm', ''), 'n', ''), 'p', ''), 'q', ''), 'r', ''), 's', ''), 't', ''), 'v', ''), 'w', ''), 'x', ''), 'y', ''), 'z', '')
end
GO
