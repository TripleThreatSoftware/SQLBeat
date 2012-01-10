/****** Object:  StoredProcedure [dbo].[pr_processPerformanceLog_stage]    Script Date: 01/10/2012 16:47:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_processPerformanceLog_stage]
as
begin

	declare @nMaxUkey bigint
	declare @nMinUkey bigint
	declare @nMinRunstamp bigint
	declare @nMaxRunstamp bigint

	set ansi_warnings off

	declare @nSixHours bigint
	set @nSixHours = dbo.fn_returnRunStamp(dateAdd(hour, -6, getDate()))

	if exists (select top 1 [name] from sysobjects where [name] = 'performanceLog_stageNew')
		drop table performanceLog_stageNew
	if exists (select top 1 [name] from sysobjects where [name] = 'performanceLog_stageOld')
		drop table performanceLog_stageOld

	CREATE TABLE [dbo].[performanceLog_stageNew](
		[ukey] [bigint] IDENTITY(1,1) NOT NULL,
		[ymd] [datetime] NULL CONSTRAINT [DF_performanceLog_stageNew_ymd]  DEFAULT (getdate()),
		[serverName] [varchar](200) NULL,
		[objectName] [varchar](255) NULL,
		[counterName] [varchar](255) NULL,
		[instanceName] [varchar](255) NULL,
		[counterValue] [decimal](30, 4) NULL,
		[counterType] [bigint] NULL,
		[runStamp] [bigint] NULL,
		[originalValue] [decimal](30, 4) NULL
		)

	CREATE CLUSTERED INDEX [ix_performanceLogStageNew_ukey] ON [dbo].[performanceLog_stageNew] (ukey) with fillfactor = 50
	CREATE INDEX [ix_performanceLogStageNew_runstamp_server_object_counter_ukey] ON [dbo].[performanceLog_stageNew] ([runStamp] ASC,[serverName] ASC,[objectName] ASC,[counterName] ASC,[ukey] ASC) with fillfactor = 50
	create index ix_performanceLogStageNew_counterType_ukey on performanceLog_stageNew (counterType, ukey) with fillfactor = 50

	begin transaction swapStagingTable

		exec sp_rename 'performanceLog_stage', 'performanceLog_stageOld'
		exec sp_rename 'performanceLog_stageNew', 'performanceLog_stage'

		set @nMaxUkey = (select max(ukey) from performanceLog_stageOld)
		if isnull(@nMaxUkey, 0) = 0
			set @nMaxUkey = (select max(ukey) from performanceLog)
		if isnull(@nMaxUkey, 0) = 0
			set @nMaxUkey = 1

		dbcc checkident('performanceLog_stage', reseed, @nMaxUkey)

		exec sp_rename 'performanceLog_stage.ix_performanceLogStageNew_runstamp_server_object_counter_ukey', 'ix_performanceLogStage_runstamp_server_object_counter_ukey', 'index'
		exec sp_rename 'performanceLog_stage.ix_performanceLogStageNew_ukey', 'ix_performanceLogStage_ukey', 'index'
		exec sp_rename 'performanceLog_stage.ix_performanceLogStageNew_counterType_ukey', 'ix_performanceLogStage_counterType_ukey', 'index'

		exec sp_rename 'DF_performanceLog_stage_ymd', 'DF_performanceLog_stageOld_ymd', 'object'
		exec sp_rename 'DF_performanceLog_stageNew_ymd', 'DF_performanceLog_stage_ymd', 'object'

	commit transaction swapStagingTable

	select
		@nMinRunstamp = min(runstamp),
		@nMaxRunstamp = max(runstamp)
		from performanceLog_stageOld (nolock)

	insert into dm_performanceObjects (objectName)
	select a.objectName
		from (select distinct objectName from performanceLog_stageOld (nolock)) a
		left outer join dm_performanceObjects b (nolock) on a.objectName = b.objectName
		where b.ukey is null

	insert into dm_performanceCounters (counterName)
	select a.counterName
		from (select distinct counterName from performanceLog_stageOld (nolock)) a
		left outer join dm_performanceCounters b (nolock) on a.counterName = b.counterName
		where b.ukey is null

	update performanceLog_stageOld with (tablock)
		set originalValue = counterValue
		where counterType in (272696576, 1073874176)

	update performanceLog_stageOld with (tablock)
		set counterValue = null
		where counterType in (272696576, 1073874176)

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

		from performanceLog_stageOld a (nolock)
		join dm_servers b (nolock) on a.serverName = b.serverName
		join dm_performanceObjects c (nolock) on a.objectName = c.objectName
		join dm_performanceCounters d (nolock) on a.counterName = d.counterName

	create clustered index ix_tmp_newRecords on #newRecords (runStamp, ukey_server, ukey_object, ukey_counter, ukey) with fillfactor = 100

	drop table performanceLog_stageOld

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
					and b.runStamp >= @nSixHours
					and b.counterType in (272696576, 1073874176)
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
GO
