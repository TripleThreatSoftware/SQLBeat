alter procedure [dbo].[pr_graph_portalLogins_byDay]
as
begin
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Portal Logins', 'Portal Logins',
		right(convert(varchar(10), ymd, 120), 5) as axis_x,
		sum(numLogins) as axis_y
		from mart_portalLogins_byHour
		group by convert(varchar(10), ymd, 120)
		order by convert(varchar(10), ymd, 120)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 400, @nHeight = 150, @bAbsoluteYAxis = 1

	drop table #dataValues
end
