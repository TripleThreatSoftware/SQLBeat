/****** Object:  UserDefinedFunction [dbo].[fn_decodeUserAgent_service]    Script Date: 12/04/2009 18:54:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_decodeUserAgent_service] (@cUserAgent varchar(2000))
returns varchar(500)
as
begin
	declare @cNewUserAgent varchar(500)

	set @cNewUserAgent =
		case
			when @cUserAgent like '%AOL%' then substring(@cUserAgent, charindex('AOL', @cUserAgent), 100)
			when @cUserAgent like '%America+Online+Browser%' then 'AOL Browser'
			when @cUserAgent like '%iTunes%' then 'iTunes'
			when @cUserAgent like '%School%' then 'School District'
			when @cUserAgent like '%Google%' then 'Google'
			when @cUserAgent like '%Facebook%' then 'Facebook'
			when @cUserAgent like '%Comcast%' then 'Comcast'
			when @cUserAgent like '%Bellsouth%' then 'Bellsouth'
			when @cUserAgent like '%AT&T%' then 'AT&T'
			when @cUserAgent like '%Ask+Jeeves%' then 'AskJeeves'
			when @cUserAgent like '%yahoo%' and @cUserAgent like '%slurp%' then 'Yahoo'
			when @cUserAgent like '%msnbot%' then 'MSN'
			when @cUserAgent like '%ia_archiver%' then 'IA'
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
