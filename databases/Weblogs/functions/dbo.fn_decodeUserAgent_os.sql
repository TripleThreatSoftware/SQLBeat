/****** Object:  UserDefinedFunction [dbo].[fn_decodeUserAgent_os]    Script Date: 12/04/2009 18:54:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_decodeUserAgent_os] (@cUserAgent varchar(2000))
returns varchar(500)
as
begin
	declare @cNewUserAgent varchar(500)

	set @cNewUserAgent = case
			when @cUserAgent like '%MAC%' or @cUserAgent like '%PowerPC%' or @cUserAgent like '%safari%' then 'MAC'
			when @cUserAgent like '%Media+Center+PC%' then 'Windows Media Center'
			when @cUserAgent like '%Windows+%'
				then space(1) +
					substring(@cUserAgent,
						charindex('Windows+', @cUserAgent),
						case when charindex(';', substring(@cUserAgent, charindex('Windows+', @cUserAgent), 100)) > 0
							then
								charindex(';',
									substring(@cUserAgent, charindex('Windows+', @cUserAgent), 100)
									)
							else
								charindex(')',
									substring(@cUserAgent, charindex('Windows+', @cUserAgent), 100)
									)
							end
						)
			when @cUserAgent like '%Windows%'  then 'Windows'
			else ''
			end

	if charindex(';', @cNewUserAgent) > 0
		set @cNewUserAgent = left(@cNewUserAgent, charindex(';', @cNewUserAgent) - 1)

	if charindex('(', @cNewUserAgent) > 0
		set @cNewUserAgent = left(@cNewUserAgent, charindex('(', @cNewUserAgent) - 1)

	if right(@cNewUserAgent, 1) = ')'
		set @cNewUserAgent = left(@cNewUserAgent, len(@cNewUserAgent) - 1)

	set @cNewUserAgent = rtrim(ltrim(replace(replace(replace(
		@cNewUserAgent,
		'+', space(1)), space(2), space(1)), ';', '')
		))

	return @cNewUserAgent
end
GO
