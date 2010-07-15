--select top 100 * from mart_site_byday order by ymd desc


create procedure [dbo].[pr_admin_graph_yoyBasketSize] (@cToken varchar(100), @cSessionID varchar(100), @cMachineID varchar(100), @nUkeyWebsite int = 0)
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

	exec pr_admin_recordAction @cToken, @cSessionID, @cMachineID, 'Year over year basket size'
	create table #dataValues_stage (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4))

	insert into #dataValues_Stage (setName, seriesName, axis_x, axis_y)
	select
		yearPart as setName, yearPart as seriesName,
		weekPart,
		convert(decimal(10,2), 100 * convert(decimal(20,4), totalParts) / convert(decimal(20,4),purchases)) axis_y
		from (
			select datePart(year, ymd) as yearpart, datepart(week, ymd) as weekPart, min(ymd) as ymd, sum(purchases) as purchases, sum(totalParts) as totalParts
				from mart_site_byday
				where ukey_website in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))
				group by datePart(year, ymd), datepart(week, ymd)
				having count(distinct ymd) = 7
			) a
		order by yearPart, weekPart

	insert into #dataValues_Stage (setName, seriesName, axis_x, axis_y)
	select a.setName, a.setName, a.axis_x, 0
		from (
			select distinct setName, axis_x
				from ( select distinct axis_x from #dataValues_Stage ) a,
					( select distinct setName from #dataValues_Stage ) b
			) a
		left outer join #dataValues_Stage b on a.setName = b.setName
			and a.axis_x = b.axis_x
		where b.setName is null

	select *, identity(int) as sortOrder
		into #dataValues
		from #dataValues_Stage
		order by setName, seriesName, convert(int, axis_x)

	exec pr_generateGoogleChartsRequest @nWidth=1000, @nHeight=300, @bAbsoluteYAxis = 1, @bLeavePeaks = 1

	drop table #dataValues
	drop table #dataValues_Stage
end
