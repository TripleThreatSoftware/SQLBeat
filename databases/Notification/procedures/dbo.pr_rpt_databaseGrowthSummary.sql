/****** Object:  StoredProcedure [dbo].[pr_rpt_databaseGrowthSummary]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_databaseGrowthSummary] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'sqlcluster01'

	select dbName, min(ymd) as minYMD, max(ymd) as maxYMD
		into #dataPoints
		from v_databaseFileSizeLog_all
		where ymd >= dateAdd(month, -1, getDate())
			and serverName = @cServerName
			and isLog = 0
			and dbName <> 'tempdb'
		group by dbName

	set datefirst 2

	-- Overall growth
	select *, [maxSize] - minSize as sizeChange
		from (
			select a.dbName, min(ymd) as firstDay, min([size]) as minSize, max([size]) as maxSize, max(ymd) as lastDay
				from v_databaseFileSizeLog_all a (nolock)
				join #dataPoints b on a.dbName = b.dbName
					and a.ymd in (b.minYMD, b.maxYMD)
				where a.isLog = 0
					and a.dbname <> 'tempdb'
					and a.serverName = @cServerName
					and a.ymd >= dateAdd(month, -1, getDate())
				group by a.dbName
			) a
		order by dbName desc
end
GO
