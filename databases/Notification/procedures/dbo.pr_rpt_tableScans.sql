SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- pr_rpt_tableScans 'sqlcluster01', null, null

ALTER procedure [dbo].[pr_rpt_tableScans] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -48, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	if dateDiff(hour, @dStartDate, @dEndDate) > 48
		set @dStartDate = dateAdd(hour, -48, @dEndDate)

	select
		ymd,
		databaseName + '.' + tableName + '(' + convert(varchar(50), indexNumber) + ')' as objectName,
		tableScans,
		indexSeeks,
		convert(bigint, 0) as delta_tableScans,
		convert(bigint, 0) as delta_indexSeeks,
		convert(dateTime, '') as lastCheck
		into #scans
		from deepSQLStats_indexesNotOptimal (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate
		order by objectName, ymd

	create clustered index ix_tmp_scans on #scans (objectName, ymd) with fillfactor = 100

	update #scans
		set lastCheck = b.lastCheck
		from #scans a
		join (
			select a.ymd, a.objectName, max(b.ymd) as lastCheck
				from #scans a
				join #scans b on a.objectName = b.objectName
					and b.ymd < a.ymd
				group by a.ymd, a.objectName
			) b on a.ymd = b.ymd
				and a.objectName = b.objectName

	update a
		set delta_tableScans = a.tableScans - b.tableScans,
			delta_indexSeeks = a.indexSeeks - b.indexSeeks
		from #scans a
		join #scans b on a.objectName = b.objectName
			and a.lastCheck = b.ymd
		where a.tableScans >= b.tableScans
			and a.indexSeeks >= b.indexSeeks

	select top 100
		*,
		convert(decimal(10,2), tableScans / case when minutes = 0 then 1 else minutes end) as tableScansPerMinute,
		convert(decimal(10,2), indexSeeks / case when minutes = 0 then 1 else minutes end) as indexSeeksPerMinute
		from (
			select
				objectName,
				sum(delta_tableScans) as tableScans,
				sum(delta_indexSeeks) as indexSeeks,
				convert(decimal(10,2),
					convert(decimal(20,4),
						dateDiff(second,
							min(
								case
									when delta_tableScans <> 0 or delta_indexSeeks <> 0 then ymd
									else null
									end),
							max(case
									when delta_tableScans <> 0 or delta_indexSeeks <> 0 then ymd
									else null
									end)
							)
						) / 60.00) as minutes
				from #scans
				group by objectName
				having sum(delta_tableScans) <> 0 or sum(delta_indexSeeks) <> 0
			) a
		order by tableScans + indexSeeks desc

	drop table #scans
end
