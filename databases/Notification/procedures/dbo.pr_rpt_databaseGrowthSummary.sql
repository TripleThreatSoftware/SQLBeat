CREATE procedure [pr_rpt_databaseGrowthSummary] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'sqlcluster01'

	set datefirst 2

	-- Overall growth
	select *, [maxSize] - minSize as sizeChange
		from (
			select dbName, min(ymd) as firstDay, min([size]) as minSize, max([size]) as maxSize, max(ymd) as lastDay
				from v_databaseFileSizeLog_all (nolock)
				where isLog = 0
					and dbname <> 'tempdb'
					and serverName = @cServerName
					and ymd >= dateAdd(month, -2, getDate())
				group by dbName
				having max([size]) > min([size])
			) a
		order by [maxSize] - minSize desc
end



GO
