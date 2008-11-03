CREATE procedure [pr_rpt_databaseGrowthDetail] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'sqlcluster01'

	set datefirst 2

	-- Growth by week
	select dbName,
		convert(varchar(10), weekStart, 120) as weekStart,
		convert(varchar(10), weekEnd, 120) as weekEnd,
		minSize, [maxSize],
		[maxSize] - minSize as sizeChange
		from (
			select
				a.serverName, a.dbName,
				min(ymd) as weekStart,
				max(ymd) as weekEnd,
				max([size]) as maxSize,
				min([size]) as minSize
				from v_databaseFileSizeLog_all a (nolock)
	--			join (select distinct serverName, dbName from #overallGrowth) b on a.servername = b.servername and a.dbname = b.dbName
				where a.isLog = 0
					and dbname <> 'tempdb'
					and serverName = @cServerName
					and a.ymd >= dateAdd(month, -2, getDate())
				group by a.serverName, a.dbName, datePart(year, ymd), datePart(week, ymd)
			) a
		where servername = @cServerName
		order by dbName, weekStart
end



GO
