-- pr_rpt_bufferContents 'sqlcluster01', null, null

CREATE procedure [dbo].[pr_rpt_bufferContents] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -48, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	if dateDiff(hour, @dStartDate, @dEndDate) > 48
		set @dStartDate = dateAdd(hour, -48, @dEndDate)

	declare @dLastScan dateTime
	set @dLastScan = (
		select max(ymd)
			from deepSQLStats_bufferCache (nolock)
			where serverName = @cServerName
				and ymd >= @dStartDate
				and ymd < @dEndDate
		)

	select
		ymd,
		databaseName + '.' + tableName + '(' + convert(varchar(50), indexNumber) + ')' as objectName,
		buffers,
		convert(bigint, 0) as delta,
		convert(decimal(10,2), 0) as delta_relative,
		convert(dateTime, '') as lastCheck
		into #bufferChanges
		from deepSQLStats_bufferCache (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd < @dEndDate
		order by objectName, ymd

	update #bufferChanges
		set lastCheck = b.lastCheck
		from #bufferChanges a
		join (
			select a.ymd, a.objectName, max(b.ymd) as lastCheck
				from #bufferChanges a
				join #bufferChanges b on a.objectName = b.objectName
					and b.ymd < a.ymd
				group by a.ymd, a.objectName
			) b on a.ymd = b.ymd
				and a.objectName = b.objectName

	update a
		set delta = a.buffers - b.buffers,
			delta_relative = (convert(decimal(20,4), a.buffers - b.buffers) / convert(decimal(20,4), b.buffers)) * 100
		from #bufferChanges a
		join #bufferChanges b on a.objectName = b.objectName
			and a.lastCheck = b.ymd

	select objectName,
		min(buffers) as minBuffers,
		max(buffers) as maxBuffers,
		avg(buffers) as avgBuffers,
		max(case when ymd = @dLastScan then buffers else null end) as nowBuffers,
		min(ymd) as startDate,
		max(ymd) as endDate
		from #bufferChanges
		group by objectName
		order by maxBuffers desc

	drop table #bufferChanges
end



GO
