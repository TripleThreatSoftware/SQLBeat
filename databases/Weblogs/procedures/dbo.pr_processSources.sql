/****** Object:  StoredProcedure [dbo].[pr_processSources]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_processSources 'web37'

--go
CREATE procedure [dbo].[pr_processSources] (@cWebserver varchar(100) = '')
as
begin
	--if isnull(@cWebserver, '') = ''
	--	return

	declare @cThisSource varchar(1000)
	declare @nThisUkey int
	declare @cWebservername varchar(50)

	declare @bIsIIS bit
	declare @bIsApache bit

	set @nThisUkey = 0

	--if datePart(hour, getDate()) between 7 and 20
	--	and not dateName(weekday, getDate()) in ('Saturday', 'Sunday')
	--	return

	insert into fact_weblogs_stage_hist (stepName, webserver) values ('Processing sources', @cWebserver)

	if (select count(*) from fact_weblogs (nolock)) > 0
	begin
		insert into fact_weblogs_stage_hist (stepName, webserver) values ('Dealing with leftover rows', @cWebserver)

	end

	while exists (
		select top 1 sourcePath
			from dm_sources
			where ukey > @nThisUkey
--				and dateDiff(minute, isnull(lastCheck, dateAdd(week, -1, getDate())), getDate()) > isnull(checkMinuteInterval, 60)
				and isEnabled = 1
				and (sourcePath like '%' + @cWebserver + '%' or isnull(@cWebServer, '') = '')
		)
	begin
		select top 1
			@cThisSource = sourcePath,
			@nThisUkey = ukey,
			@bIsIIS = isIIS,
			@bIsApache = isApache,
			@cWebservername = left(replace(sourcePath, '\\', ''), charindex('\', replace(sourcePath, '\\', '')) - 1)
			from dm_sources
			where ukey > @nThisUkey
--				and dateDiff(minute, isnull(lastCheck, dateAdd(week, -1, getDate())), getDate()) > isnull(checkMinuteInterval, 60)
				and isEnabled = 1
				and (sourcePath like '%' + @cWebserver + '%' or isnull(@cWebServer, '') = '')
			order by ukey

		insert into fact_weblogs_stage_hist (stepName, webserver, ukey_source) values ('Importing from "' + @cThisSource + '"', @cWebservername, @nThisUkey)

		begin try
			exec pr_importWeblogs @nThisUkey

			update dm_sources set lastCheck = getDate() where ukey = @nThisUkey
		end try
		begin catch
			insert into fact_weblogs_stage_hist (stepName, webserver, ukey_source) values ('Error: ' + convert(varchar(20), @@error), @cWebservername, @nThisUkey)
			insert into fact_weblogs_stage_hist (stepName, webserver, ukey_source) values (error_message(), @cWebservername, @nThisUkey)
		end catch

	end
end
GO
