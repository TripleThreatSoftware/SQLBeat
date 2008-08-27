create procedure pr_graph_serversDown
as
begin
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues	(setName, seriesName, axis_x, axis_y)
	select
		'Servers Down',
		'Servers Down',
		case
			when datePart(hour, a.ymd) <= 12
				then convert(varchar(2), datePart(hour, a.ymd)) + 'a'
				else convert(varchar(2), datePart(hour, a.ymd) - 12) + 'p'
			end as axis_x,
		count(distinct case when b.isEnabled = 1 then a.serverName else null end) as axis_y
		from notification..pingLog a
		join notification..dm_servers b on a.serverName = b.serverName
		join notification..dm_serverGroups c on b.ukey_group = c.ukey
			and (c.isProduction = 1 or c.groupName in ('Application Support', 'Network Support'))
		where a.isServerPingable = 0
			and a.ymd >= dateAdd(hour, -12, getDate())
		group by datePart(hour, a.ymd)
		order by min(ymd)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 400, @nHeight = 150, @bAbsoluteYAxis = 1

	drop table #dataValues
end
