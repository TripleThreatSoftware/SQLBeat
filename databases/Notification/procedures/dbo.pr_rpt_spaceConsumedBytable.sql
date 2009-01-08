--drop view v_tableSizeLog_all
GO
ALTER procedure [dbo].[pr_rpt_spaceConsumedByTable] (@cServerName varchar(100), @cDatabaseName varchar(100))
as
begin
	create table #dataValues (seriesName varchar(100), setName varchar(100), axis_x varchar(100), axis_y int, sortOrder int identity)

	select top 5
		databaseName, tableName, max(dbo.fn_returnDigits(reserved, 0)) as reserved
		into #biggestTables
		from tableSizeLog (nolock)
		where (databaseName = @cDatabaseName or isnull(@cDatabaseName, '') = '')
			and (serverName = @cServerName or isnull(@cServerName, '') = '')
			and ymd >= dateAdd(week, -1, getDate())
		group by databaseName, tableName
		order by max(dbo.fn_returnDigits(reserved, 0)) desc

	insert into #dataValues (seriesName, setName, axis_x, axis_y)
	select
		a.tableName, a.tableName,
		convert(varchar(10), min(a.ymd), 120),
		max(dbo.fn_returnDigits(a.reserved, 0)) / 1024 as totalReserved
		from v_tableSizeLog_all a (nolock)
		join #biggestTables b on a.databaseName = b.databaseName
			and a.tableName = b.tableName
		where (a.databaseName = @cDatabaseName or isnull(@cDatabaseName, '') = '')
			and (a.serverName = @cServerName or isnull(@cServerName, '') = '')
			and dateDiff(day, a.ymd, getDate()) / 7 <= 10
		group by a.databaseName, a.tableName, dateDiff(day, a.ymd, getDate()) / 7
		order by a.databaseName, a.tableName, dateDiff(day, a.ymd, getDate()) / 7 desc

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bAbsoluteYAxis = 1

	drop table #biggestTables
	drop table #dataValues
end
