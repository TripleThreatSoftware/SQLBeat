/****** Object:  StoredProcedure [dbo].[pr_rpt_databaseSizeOverTime]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_rpt_databaseSizeOverTime] (@cServerName varchar(100))
as
begin
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		dbname,
		'space consumed over time',
			right(convert(varchar(10), min(ymd), 120), 2) + ' ' +
				case when datePart(hour, min(ymd)) <= 12 then convert(varchar(20), datePart(hour, min(ymd))) else convert(varchar(20), datePart(hour, min(ymd))-12) end +
				case when datePart(hour, min(ymd)) <= 12 then 'a' else 'p' end ,
		max(size)
		from (
			select dbName, ymd, sum(size) as size
				from databaseFileSizeLog
				where servername = @cServerName
--					and left(fileName, 1) = 'S'
					and ymd >= dateAdd(day, -4, getDate())
				group by dbName, ymd
			) a
		group by dbname,
			convert(varchar(10), ymd, 120),
			datePart(hour, ymd) / 2
		order by 	dbname,
			convert(varchar(10), ymd, 120),
			datePart(hour, ymd) / 2

	delete from #dataValues where setName not in (
		select top 5 dbName
			from (
				select dbName, ymd, sum(size) as size
					from databaseFileSizeLog
					where servername = @cServerName
--						and left(fileName, 1) = 'S'
					and ymd >= dateAdd(day, -4, getDate())
					group by dbName, ymd
				) a
			group by dbName
			order by max(size) desc
		)

	exec pr_generateGoogleChartsRequest @nWidth=700, @nHeight=400, @bAbsoluteYAxis = 1

	drop table #dataValues
end
GO
