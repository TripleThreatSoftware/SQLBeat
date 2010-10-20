SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_admin_graph_organicBounceRateByEntryPageByDay 'cole', '', '', 7
alter procedure [dbo].[pr_admin_graph_organicBounceRateByEntryPageByDay] (@cToken varchar(100), @cSessionID varchar(100), @cMachineID varchar(100), @nUkeyWebsite int = 0)
as
begin

	declare @nUkeyUser int

	select @nUkeyUser = ukey_user
		from dbo.fn_admin_validateCredentials(@cToken)

	if @nUkeyWebsite <> 0 and @nUkeyWebsite not in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser)
		return

	if @nUkeyUser is null
	begin
		return
	end

	exec pr_admin_recordAction @cToken, @cSessionID, @cMachineID, 'Organic bounce rate by entry page'

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)

	select
		isnull(entryPage, 'N/A') as setName,
		isnull(entryPage, 'N/A') as seriesName,
		right(convert(varchar(10), min(ymd), 120), 5) as ymd,

		convert(decimal(10,2), 100 * convert(decimal(20,4), sum(case when pageViews = 1 then 1 else 0 end)) / convert(decimal(20,4), count(*))) as bounceRate

		from mart_Sessions_byday a (nolock)
		where ymd >= dateAdd(day, -45, getdate())
			and isnull(partner, '') = ''
--			and ukey_website in (1,2,3,7)
			and entryPage not like '%cart%'
			and entryPage not like '%orderStatus%'
			and entryPage not like '%checkout%'
			and entryPage not like '%requestcatalog%'
--			and machineID = sessionID
			and isnull(entryPage, 'N/A') in (
				select isnull(entryPage, 'N/A')
					from mart_sessions_byday a (nolock)
					where ymd >= dateAdd(day, -10, getDate())
						and isnull(partner, '') = ''
						and a.ukey_website in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))
					group by isnull(entryPage, 'N/A')
					having count(*) > 200
				)
			and a.ukey_website in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))
		group by entryPage, convert(varchar(10), ymd, 120)
		order by entryPage, min(ymd)

	exec pr_generateGoogleChartsRequest @nWidth=800, @nHeight=300, @bAbsoluteYAxis = 1

	drop table #dataValues

end
