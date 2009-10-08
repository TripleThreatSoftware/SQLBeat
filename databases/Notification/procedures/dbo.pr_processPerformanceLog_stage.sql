ALTER procedure [dbo].[pr_processPerformanceLog_stage]
as
begin

	declare @nMaxUkey bigint
	declare @nMinUkey bigint
	declare @nMinRunstamp bigint
	declare @nMaxRunstamp bigint

	select
		@nMaxUkey = max(ukey),
		@nMinUkey = min(ukey),
		@nMinRunstamp = min(runstamp),
		@nMaxRunstamp = max(runstamp)
		from performanceLog_stage (nolock)

	insert into dm_performanceObjects (objectName)
	select a.objectName
		from (select distinct objectName from performanceLog_stage (nolock) where ukey <= @nMaxUkey) a
		left outer join dm_performanceObjects b (nolock) on a.objectName = b.objectName
		where b.ukey is null

	insert into dm_performanceCounters (counterName)
	select a.counterName
		from (select distinct counterName from performanceLog_stage (nolock) where ukey <= @nMaxUkey) a
		left outer join dm_performanceCounters b (nolock) on a.counterName = b.counterName
		where b.ukey is null

	update performanceLog_stage with (rowlock)
		set originalValue = counterValue
		where ukey <= @nMaxUkey
			and counterType in (272696576, 1073874176)

	update performanceLog_stage with (rowlock)
		set counterValue = null
		where ukey <= @nMaxUkey
			and counterType in (272696576, 1073874176)

	select
		a.runStamp,
		a.ymd,
		b.ukey as ukey_server,
		c.ukey as ukey_object,
		d.ukey as ukey_counter,
		a.instanceName,
		a.counterValue,
		a.counterType,
		a.ukey,
		a.originalValue

		into #newRecords

		from performanceLog_stage a (nolock)
		join dm_servers b (nolock) on a.serverName = b.serverName
		join dm_performanceObjects c (nolock) on a.objectName = c.objectName
		join dm_performanceCounters d (nolock) on a.counterName = d.counterName

		where a.runstamp <= @nMaxRunstamp

	create clustered index ix_tmp_newRecords on #newRecords (runStamp, ukey_server, ukey_object, ukey_counter, ukey) with fillfactor = 100

	delete from performanceLog_stage with (tablock) where runstamp <= @nMaxRunstamp

	-- get rid of duplicates
	delete #newRecords
		from #newRecords a
		join performanceLog e (nolock) on a.runStamp = e.runStamp
			and a.ukey_server = e.ukey_server
			and a.ukey_object = e.ukey_object
			and a.ukey_counter = e.ukey_counter

	insert into performanceLog (runStamp, ymd, ukey_server, ukey_object, ukey_counter, instanceName, counterValue, counterType, ukey, originalValue)
	select *
		from #newRecords

	update a with (rowlock)
		set counterValue = (a.originalValue - c.originalValue) / dateDiff(second, c.ymd, a.ymd)
		from performanceLog a with (rowlock)
		join (
			select a.runStamp, a.ukey_server, a.ukey_object, a.ukey_counter, a.instanceName,
				max(b.runStamp) as runstamp_previous
				from performanceLog a (nolock)
				join performanceLog b (nolock) on a.ukey_server = b.ukey_server
					and a.ukey_object = b.ukey_object
					and a.ukey_counter = b.ukey_counter
					and a.instanceName = b.instanceName
					and b.runStamp < a.runStamp
					and b.runStamp >= dbo.fn_returnRunStamp(dateAdd(hour, -12, getDate()))
				where a.counterType in (272696576, 1073874176)
					and a.counterValue is null
					and a.runStamp >= @nMinRunstamp
				group by a.runStamp, a.ukey_server, a.ukey_object, a.ukey_counter, a.instanceName
			) b on a.ukey_server = b.ukey_server
				and a.ukey_object = b.ukey_object
				and a.ukey_counter = b.ukey_counter
				and a.instanceName = b.instanceName
				and a.runStamp = b.runStamp
		join performanceLog c (nolock) on a.ukey_server = c.ukey_server
			and a.ukey_object = c.ukey_object
			and a.ukey_counter = c.ukey_counter
			and a.instanceName = c.instanceName
			and c.runStamp = b.runstamp_previous
		where a.counterType in (272696576, 1073874176)
			and a.counterValue is null
			and a.runStamp >= @nMinRunstamp

	drop table #newRecords
end


--update performanceLog_stage with (rowlock)
--	set runStamp = convert(bigint,
--			convert(varchar(4), datePart(year, ymd)) +
--			dbo.fn_padl(convert(varchar(2), datePart(month, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(2), datePart(day, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(2), datePart(hour, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(2), datePart(minute, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(2), datePart(second, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(3), datePart(millisecond, ymd)), 3, '0')
--		)
--	where runStamp = 20071012101303660
