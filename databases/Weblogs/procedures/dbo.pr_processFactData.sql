/****** Object:  StoredProcedure [dbo].[pr_processFactData]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [pr_processFactData] @bRecoverFromFailure = 1
CREATE procedure [dbo].[pr_processFactData] (@bRecoverFromFailure bit = 0)
as
begin
	declare @dStartDate dateTime
	declare @dEndDate datetime
	declare @bRecordsDeleted bit
	declare @bIsIIS bit

	set @bIsIIS = 1

	if @bRecoverFromFailure = 0
	begin

		if (select count(*) from fact_weblogs (nolock)) = 0
			return

		if exists (select top 1 id from sysobjects where name = 'fact_weblogs_daily')
			drop table fact_weblogs_daily

		begin transaction
			select *
				into fact_weblogs_daily
				from fact_weblogs

			truncate table fact_weblogs
		commit transaction

	end

	insert into fact_weblogs_stage_hist (stepName) values ('Counting records')

	select
		ukey_sourceFile,
		ukey_site,
		datePart(year, ymd) as ymd_year,
		datePart(week, ymd) as ymd_week,
		min(convert(varchar(10), ymd, 120)) as startDate,
		max(convert(varchar(10), ymd, 120)) as endDate,
		count(*) as numRecords
		into #datesImported
		from fact_weblogs_daily (nolock)
		group by ukey_site, ukey_sourceFile, datePart(week, ymd), datePart(year, ymd)

	create clustered index ix_tmp_datesImported on #datesImported (startDate, endDate, ukey_site, ukey_sourceFile) with fillfactor = 100

	select @dStartDate = min(startDate), @dEndDate = max(endDate) from #datesImported

	insert into fact_weblogs_stage_hist (stepName) values ('Deleting duplicates')

	if exists (select top 1 [name] from sysobjects where [name] = 'v_fact_weblogs_all')
	begin

		set @bRecordsDeleted = 0

		--if (select sum(numRecords) from #datesImported) < 1000000
		--begin
		--	insert into fact_weblogs_stage_hist (stepName) values ('Deleting duplicates from view')

		--	-- this code deletes any existing records for this import file, which assumes the files are fairly small
		--	-- and there is not a significant overhead to replacing all the records
		--	begin try
		--		delete v_fact_weblogs_all
		--			from v_fact_weblogs_all a
		--			join #datesImported b on a.ukey_sourceFile = b.ukey_sourceFile
		--				and a.ukey_site = b.ukey_site
		--				and a.ymd >= b.startDate
		--				and a.ymd <= b.endDate
		--			where a.ymd >= @dStartDate
		--				and a.ymd < dateAdd(day, 1, @dEndDate)

		--		set @bRecordsDeleted = 1
		--	end try
		--	begin catch
		--		print error_message()
		--	end catch
		--end

		if @bRecordsDeleted = 0
		begin
			insert into fact_weblogs_stage_hist (stepName) values ('Deleting duplicates from fact table')

			-- this code removes incoming records that we already have in the kitty
			-- this is useful when we have a whole mess of incoming data
			delete fact_weblogs_daily with (tablock)
				from fact_weblogs_daily a
				join v_fact_weblogs_all b on a.ukey_sourceFile = b.ukey_sourceFile
					and a.ukey_site = b.ukey_site
					and a.ymd = b.ymd
					and a.ukey_method = b.ukey_method
					and a.ukey_clientIP = b.ukey_clientIP
					and a.ukey_uriStem = b.ukey_uriStem
					and a.queryString = b.queryString
					and b.ymd >= @dStartDate
					and b.ymd < dateAdd(day, 1, @dEndDate)
				join #datesImported c on b.ukey_sourceFile = c.ukey_sourceFile
					and b.ukey_site = c.ukey_site
					and b.ymd >= c.startDate
					and b.ymd < dateAdd(day, 1, c.endDate)
		end
	end

	insert into fact_weblogs_stage_hist (stepName) values ('Setting sessionID values')

	update fact_weblogs_daily with (tablock)
		set sessionID = isnull(dbo.fn_returnKeyValue(cookie, 'ASP.NET_SessionId', ';+'), convert(varchar(20), ukey_clientIP) + space(1) + convert(varchar(20), ukey_userAgent)),
			appSessionID = isnull(dbo.fn_returnKeyValue(cookie, 'GBaseSessionID', ';+'), '') + isnull(dbo.fn_returnKeyValue(cookie, 'GBaseUserID', ';+'), '')
		where cookie is not null
			and @bIsIIS = 1

	update fact_weblogs_daily with (tablock)
		set sessionID = isnull(dbo.fn_returnKeyValue(queryString, 'p_usercode', '&'), convert(varchar(20), ukey_clientIP) + space(1) + convert(varchar(20), ukey_userAgent)),
			appSessionID = isnull(dbo.fn_returnKeyValue(queryString, 'p_usercode', '&'), '')
		where queryString like '%p_usercode%'

	insert into fact_weblogs_stage_hist (stepName) values ('Partitioning')

	begin try
		--exec pr_partitionTableDaily 'fact_weblogs', 'ymd', 'ukey_site, ukey_sourceFile, ukey_uriStem, ukey_clientIP, ukey_userAgent, ukey', 0
		-- I'm not sure that supplying the @cKeyFieldList value does anything for us here .. but I don't think it hurts either. Hard to tell what comes of it downstream. I think it's for de-duplication.
		exec pr_partitionTableDaily 'fact_weblogs_daily', 'ymd', 'ukey_site, ukey_sourcefile, ymd, ukey', 0, 'Cluster'

		insert into fact_weblogs_stage_hist (stepName) values ('Creating indexes')
		exec pr_createIndexOnAllPartitionTables 'fact_weblogs', 'site_source_ymd', 'ukey_site, ukey_sourcefile, ymd', 80
	end try

	begin catch
		-- if daily tables have been recreated on top of weekly tables, try and combine daily and weekly tables
		if error_message() like '%partitioning column%'
		begin
			--exec pr_archiveOldPartitionedTables 'fact_weblogs', 'ymd', 'ukey_site, ukey_sourceFile, ukey_uriStem, ukey_clientIP, ukey_userAgent, ukey'
			exec pr_archiveOldPartitionedTables 'fact_weblogs', 'ymd', 'ukey_site, ukey_sourcefile, ymd, ukey'
		end

		insert into fact_weblogs_stage_hist (stepName) values ('Error: ' + convert(varchar(20), @@error))
		insert into fact_weblogs_stage_hist (stepName) values (error_message())

		insert into notification..notificationLog_stage (serverName, severity, subject, message) values ('Weblog Monitoring', 2, 'Partitioning failed', isnull(@@error + char(13) + char(13), '') + error_message())
	end catch

	drop table #datesImported

	drop table fact_weblogs_daily
end
GO
