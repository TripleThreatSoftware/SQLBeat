/****** Object:  StoredProcedure [dbo].[pr_processSources]    Script Date: 12/04/2009 18:51:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select count(*), min(ymd), max(ymd) from fact_weblogs (nolock)
-- select top 1000 * from fact_weblogs_stage_hist (nolock) order by ukey desc
-- sp_who2
-- exec pr_importWeblogs '\\appweb06\d$\iis logfiles\'
--select * from dm_sources
--update dm_sources set isEnabled = 1 where sourcePath like '%appweb%'
--alter table dm_sources add isEnabled bit default 0

--go
CREATE procedure [dbo].[pr_processSources]
as
begin
	declare @cThisSource varchar(1000)
	declare @nThisUkey int
	declare @dStartDate dateTime
	declare @dEndDate datetime
	declare @bIsIIS bit
	declare @bIsApache bit

	set @nThisUkey = 0

	insert into fact_weblogs_stage_hist (stepName) values ('Processing sources')

	while exists (
		select top 1 sourcePath
			from dm_sources
			where ukey > @nThisUkey
				and dateDiff(minute, isnull(lastCheck, dateAdd(week, -1, getDate())), getDate()) > isnull(checkMinuteInterval, 60)
				and isEnabled = 1
		)
	begin
		select top 1 @cThisSource = sourcePath,
			@nThisUkey = ukey,
			@bIsIIS = isIIS,
			@bIsApache = isApache
			from dm_sources
			where ukey > @nThisUkey
				and dateDiff(minute, isnull(lastCheck, dateAdd(week, -1, getDate())), getDate()) > isnull(checkMinuteInterval, 60)
				and isEnabled = 1
			order by ukey

		insert into fact_weblogs_stage_hist (stepName) values ('Importing from "' + @cThisSource + '"')

		begin try
			exec pr_importWeblogs @nThisUkey
		end try
		begin catch
			insert into fact_weblogs_stage_hist (stepName) values ('Error: ' + convert(varchar(20), @@error))
			insert into fact_weblogs_stage_hist (stepName) values (error_message())
		end catch


		if (select count(*) from fact_weblogs (nolock)) > 0
		begin

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
				from fact_weblogs
				group by ukey_site, ukey_sourceFile, datePart(week, ymd), datePart(year, ymd)

			create clustered index ix_tmp_datesImported on #datesImported (startDate, endDate, ukey_site, ukey_sourceFile) with fillfactor = 100

			select @dStartDate = min(startDate), @dEndDate = max(endDate) from #datesImported

			insert into fact_weblogs_stage_hist (stepName) values ('Deleting duplicates')

			if exists (select top 1 [name] from sysobjects where [name] = 'v_fact_weblogs_all')
			begin
				if (select sum(numRecords) from #datesImported) < 1000000
				begin
					insert into fact_weblogs_stage_hist (stepName) values ('Deleting duplicates from view')

					-- this code deletes any existing records for this import file, which assumes the files are fairly small
					-- and there is not a significant overhead to replacing all the records
					delete v_fact_weblogs_all
						from v_fact_weblogs_all a
						join #datesImported b on a.ukey_sourceFile = b.ukey_sourceFile
							and a.ukey_site = b.ukey_site
							and a.ymd >= b.startDate
							and a.ymd <= b.endDate
						where a.ymd >= @dStartDate
							and a.ymd < dateAdd(day, 1, @dEndDate)
				end
				else
				begin
					insert into fact_weblogs_stage_hist (stepName) values ('Deleting duplicates from fact table')

					-- this code removes incoming records that we already have in the kitty
					-- this is useful when we have a whole mess of incoming data
					delete fact_weblogs with (tablock)
						from fact_weblogs a
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

			update fact_weblogs with (tablock)
				set sessionID = isnull(dbo.fn_returnKeyValue(cookie, 'ASP.NET_SessionId', ';+'), convert(varchar(20), ukey_clientIP) + space(1) + convert(varchar(20), ukey_userAgent)),
					appSessionID = isnull(dbo.fn_returnKeyValue(cookie, 'GBaseSessionID', ';+'), '') + isnull(dbo.fn_returnKeyValue(cookie, 'GBaseUserID', ';+'), '')
				where cookie is not null
					and @bIsIIS = 1

			update fact_weblogs with (tablock)
				set sessionID = isnull(dbo.fn_returnKeyValue(queryString, 'p_usercode', '&'), convert(varchar(20), ukey_clientIP) + space(1) + convert(varchar(20), ukey_userAgent)),
					appSessionID = isnull(dbo.fn_returnKeyValue(queryString, 'p_usercode', '&'), '')
				where queryString like '%p_usercode%'

			insert into fact_weblogs_stage_hist (stepName) values ('Partitioning')

			begin try
				exec pr_partitionTableDaily 'fact_weblogs', 'ymd', 'ukey_site, ukey_sourceFile, ukey_uriStem, ukey_clientIP, ukey_userAgent, ukey', 0

				insert into fact_weblogs_stage_hist (stepName) values ('Creating indexes')
				exec pr_createIndexOnAllPartitionTables 'fact_weblogs', 'ukeySite', 'ukey_site, ukey_sourceFile, ymd', 70
			end try

			begin catch
				-- if daily tables have been recreated on top of weekly tables, try and combine daily and weekly tables
				if error_message() like '%partitioning column%'
					exec pr_archiveOldPartitionedTables 'fact_weblogs', 'ymd', 'ukey_site, ukey_sourceFile, ukey_uriStem, ukey_clientIP, ukey_userAgent, ukey'

				insert into fact_weblogs_stage_hist (stepName) values ('Error: ' + convert(varchar(20), @@error))
				insert into fact_weblogs_stage_hist (stepName) values (error_message())

				insert into notification..notificationLog_stage (serverName, severity, subject, message) values ('Weblog Monitoring', 2, 'Partitioning failed', isnull(@@error + char(13) + char(13), '') + error_message())
			end catch

	--		insert into fact_weblogs_stage_hist (stepName) values ('Selecting dates for marting')
	--
	--		set @dStartDate = ''
	--
	--		insert into fact_weblogs_stage_hist (stepName) values ('Marting')
	--
	--		-- because we've de-duplicated, the query we had before is crap
	--		select
	--			datePart(year, ymd) as ymd_year,
	--			datePart(week, ymd) as ymd_week,
	--			min(convert(varchar(10), ymd, 120)) as startDate,
	--			max(convert(varchar(10), ymd, 120)) as endDate
	--			into #datesToMart
	--			from fact_weblogs
	--			group by datePart(week, ymd), datePart(year, ymd)
	--
	--		insert into fact_weblogs_stage_hist (stepName) values ('Marting starting for ' + convert(varchar(10), @@rowcount) + ' weeks.')
	--
	--		while exists (select top 1 ymd_week from #datesToMart where startDate > @dStartDate)
	--		begin
	--			select top 1
	--				@dStartDate = startDate,
	--				@dEndDate = endDate
	--				from #datesToMart
	--				where startDate > @dStartDate
	--				order by ymd_year, ymd_week
	--
	--			insert into fact_weblogs_stage_hist (stepName) values ('Marting for "' + convert(varchar(10), @dStartDate, 120) + '" - "' + convert(varchar(10), @dEndDate, 120) + '"')
	--
	--			exec pr_mart_site @dStartDate, @dEndDate
	----			exec pr_mart_page @dStartDate, @dEndDate
	--		end

			drop table #datesImported
		end

		truncate table fact_weblogs
--		drop table #datesToMart

	end
end
GO
