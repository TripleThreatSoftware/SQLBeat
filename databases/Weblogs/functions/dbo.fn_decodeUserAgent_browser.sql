USE [Weblogs]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_decodeUserAgent_browser]    Script Date: 9/30/2013 3:49:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select dbo.fn_decodeUserAgent_browser('Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv 11.0) like Gecko')
-- select dbo.fn_decodeUserAgent_browser('Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)')

ALTER function [dbo].[fn_decodeUserAgent_browser] (@cUserAgent varchar(2000))
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
			when @cUserAgent like '%opera%' and charindex('(', @cUserAgent) > 0 then left(@cUserAgent, charindex('(', @cUserAgent) - 1)
			when @cUserAgent like '%safari%' then substring(@cUserAgent, charindex('Safari', @cUserAgent), 100)
			when @cUserAgent like '%firefox%' then substring(@cUserAgent, charindex('firefox', @cUserAgent), 100)
			when @cUserAgent like '%netscape%' then substring(@cUserAgent, charindex('netscape', @cUserAgent), 100)
			when @cUserAgent like '%America+Online+Browser%' then substring(@cUserAgent, charindex('America+Online+Browser', @cUserAgent), 100)
			when @cUserAgent like '%MSIE%' then substring(@cUserAgent, charindex('MSIE', @cUserAgent), 100)
			when @cUserAgent like '%Trident%' then 'MSIE ' + substring(@cUserAgent, charindex('rv ', @cUserAgent) + 3, 5)
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
