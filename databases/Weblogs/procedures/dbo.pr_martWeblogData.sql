USE [Weblogs]
GO
/****** Object:  StoredProcedure [dbo].[pr_martWeblogData]    Script Date: 9/24/2024 10:49:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_martWeblogData]
as
begin

	declare @dStartProcessing dateTime
	declare @cSubject varchar(2000)
	declare @cMessage varchar(8000)

	declare @dToday dateTime
	set @dStartProcessing = (
		select isnull(max(ymd), convert(varchar(10), getDate(), 120))
			from fact_weblogs_stage_hist (nolock)
			where stepName = 'Mart Starting'
		)

	if @dStartProcessing is null
		set @dStartProcessing = convert(varchar(10), dateadd(day, -1, getDate()), 120)

	insert into fact_weblogs_stage_hist (stepName) values ('Mart Starting')

	create table #dates (ymd dateTime)
	insert into #dates
	select distinct ymd
		from (
			select distinct convert(varchar(10), minYMD, 120) as ymd
				from dm_sourceFiles
				where dateAdded >= @dStartProcessing
			union
			select distinct convert(varchar(10), maxYMD, 120) as ymd
				from dm_sourceFiles
				where dateAdded >= @dStartProcessing
			) a
		where ymd is not null

	set @dToday = ''
	while exists (select top 1 ymd from #dates where ymd > @dToday and ymd >= dateAdd(month, -3, getDate()))
	begin
		select top 1 @dToday = ymd
			from #dates
			where ymd > @dToday and ymd >= dateAdd(month, -3, getDate())
			order by ymd

		insert into fact_weblogs_stage_hist (stepName) values ('MART - Processing Page ' + convert(varchar(10), @dToday, 120) + '.')
		begin try
			exec pr_mart_page @dToday, @dToday
		end try
		begin catch
			set @cSubject = 'pr_martWeblogData failure - pr_mart_page @ ' + convert(varchar(20), getDate(), 120)
			set @cMessage = error_message()

			insert into notification..notificationLog_stage (ymd, subject, message, serverName) values (getDate(), @cSubject, @cMessage, @@servername)
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('MART - pr_mart_site_page ' + convert(varchar(10), @dToday, 120) + '.')
		begin try
			exec pr_mart_site_page @dToday, @dToday
		end try
		begin catch
			set @cSubject = 'pr_martWeblogData failure - pr_mart_site_page @ ' + convert(varchar(20), getDate(), 120)
			set @cMessage = error_message()

			insert into notification..notificationLog_stage (ymd, subject, message, serverName) values (getDate(), @cSubject, @cMessage, @@servername)
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('MART - Processing User ' + convert(varchar(10), @dToday, 120) + '.')
		begin try
			exec pr_mart_userAgent @dToday, @dToday
		end try
		begin catch
			set @cSubject = 'pr_martWeblogData failure - pr_mart_userAgent @ ' + convert(varchar(20), getDate(), 120)
			set @cMessage = error_message()

			insert into notification..notificationLog_stage (ymd, subject, message, serverName) values (getDate(), @cSubject, @cMessage, @@servername)
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('MART - Processing Site ' + convert(varchar(10), @dToday, 120) + '.')
		begin try
			exec pr_mart_site @dToday, @dToday
		end try
		begin catch
			set @cSubject = 'pr_martWeblogData failure - pr_mart_site @ ' + convert(varchar(20), getDate(), 120)
			set @cMessage = error_message()

			insert into notification..notificationLog_stage (ymd, subject, message, serverName) values (getDate(), @cSubject, @cMessage, @@servername)
		end catch

		insert into fact_weblogs_stage_hist (stepName) values ('MART - Day Done ' + convert(varchar(10), @dToday, 120) + '.')
	end
end
