USE [Weblogs]
GO
/****** Object:  StoredProcedure [dbo].[pr_processSources]    Script Date: 6/26/2014 3:37:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select count(*), min(ymd), max(ymd) from fact_weblogs (nolock)
-- select top 1000 * from fact_weblogs_stage_hist (nolock) order by ukey desc
-- select top 1 * from v_fact_weblogs_all where ymd
-- select * from scheduler.dbo.jobs order by jobname
-- select top 100 * from scheduler.dbo.jobHistory where ukey_job = 315 order by ymd desc
-- exec scheduler.dbo.pr_job_stop 315
-- exec scheduler.dbo.pr_job_start 315
-- sp_who2
-- exec pr_importWeblogs '\\appweb06\d$\iis logfiles\'
--select * from dm_sources
--update dm_sources set isEnabled = 1 where sourcePath like '%appweb%'
--alter table dm_sources add isEnabled bit default 0

--go
ALTER procedure [dbo].[pr_processSources]
as
begin
	declare @cThisSource varchar(1000)
	declare @nThisUkey int

	declare @bIsIIS bit
	declare @bIsApache bit

	set @nThisUkey = 0

	--if datePart(hour, getDate()) between 7 and 20
	--	and not dateName(weekday, getDate()) in ('Saturday', 'Sunday')
	--	return

	insert into fact_weblogs_stage_hist (stepName) values ('Processing sources')

	if (select count(*) from fact_weblogs (nolock)) > 0
	begin
		insert into fact_weblogs_stage_hist (stepName) values ('Dealing with leftover rows')

	end

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

		exec pr_processFactData
	end
end
