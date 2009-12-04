/****** Object:  UserDefinedFunction [dbo].[fn_decodeUserAgent_browser]    Script Date: 12/04/2009 18:54:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_decodeUserAgent_browser] (@cUserAgent varchar(2000))
returns varchar(500)
as
begin
	declare @cNewUserAgent varchar(500)

	set @cNewUserAgent =
		case
			when @cUserAgent like '%iTunes%' then 'iTunes Browser'
			when @cUserAgent like '%GoogleBot%' then 'GoogleBot'
			when @cUserAgent like '%Ask+Jeeves%' and @cUserAgent like '%Teoma%' and @cUserAgent like '%crawl%' then 'AskJeeves Crawler'
			when @cUserAgent like '%yahoo%' and @cUserAgent like '%slurp%' then 'YahooSlurp Crawler'
			when @cUserAgent like '%msnbot%' then 'MSNBot'
			when @cUserAgent like '%crawler%' then 'Crawler - Unknown'
			when @cUserAgent like '%robot%' then 'Robot - Unknown'
			when @cUserAgent like '%bot%' then 'Bot - Unknown'

			when @cUserAgent = 'opera' then @cUserAgent
			when @cUserAgent like '%opera%' then left(@cUserAgent, charindex('(', @cUserAgent) - 1)
			when @cUserAgent like '%safari%' then substring(@cUserAgent, charindex('Safari', @cUserAgent), 100)
			when @cUserAgent like '%firefox%' then substring(@cUserAgent, charindex('firefox', @cUserAgent), 100)
			when @cUserAgent like '%netscape%' then substring(@cUserAgent, charindex('netscape', @cUserAgent), 100)
			when @cUserAgent like '%America+Online+Browser%' then substring(@cUserAgent, charindex('America+Online+Browser', @cUserAgent), 100)
			when @cUserAgent like '%MSIE%' then substring(@cUserAgent, charindex('MSIE', @cUserAgent), 100)
			when left(@cUserAgent, 8) = 'Mozilla/'
				then left(@cUserAgent, 12) + ' ' + dbo.fn_returnListItem(substring(@cUserAgent, 14, 1000), 2, ';')
			else @cUserAgent
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
