alter procedure [dbo].[pr_graph_portalLogins_byHour]
as
begin
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		'Portal Logins', 'Portal Logins',
--		right(convert(varchar(10), ymd, 120), 5) + space(1) +
			convert(varchar(2),
				case
					when datePart(hour, ymd) >= 13
						then datePart(hour, ymd) - 12
						else datePart(hour, ymd)
						end) +
					case
						when datePart(hour, ymd) >= 13
						then 'p'
						else 'a'
					end
					as axis_x,
		sum(numLogins) as axis_y
		from mart_portalLogins_byHour
		where ymd >= dateAdd(hour, -72, getDatE())
		group by
--			right(convert(varchar(10), ymd, 120), 5) + space(1) +
			convert(varchar(2),
				case
					when datePart(hour, ymd) >= 13
						then datePart(hour, ymd) - 12
						else datePart(hour, ymd)
						end) +
					case
						when datePart(hour, ymd) >= 13
						then 'p'
						else 'a'
					end
		order by min(ymd)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 400, @nHeight = 150, @bAbsoluteYAxis = 1

	drop table #dataValues
end
