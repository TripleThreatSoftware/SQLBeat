/****** Object:  StoredProcedure [dbo].[pr_rpt_enterprisePINGSummary]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_rpt_enterprisePINGSummary]
as
begin
	set nocount on

	declare @dRightNow dateTime
	declare @nNumHours int
	set @dRightNow = (select max(ymd) from pingLog (nolock))
	set @nNumHours = 12

	select
		serverName,
		convert(decimal(10,2), avg(
			(
				case when isnull(pingTime1, 0) = 0 then 9999 else pingTime1 end +
				case when isnull(pingTime2, 0) = 0 then 9999 else pingTime2 end +
				case when isnull(pingTime3, 0) = 0 then 9999 else pingTime3 end +
				case when isnull(pingTime4, 0) = 0 then 9999 else pingTime4 end
				) / 4.00
			)) as serverPing_now,
		count(distinct ymd) as numChecks_now,

		convert(decimal(10,2), 0) as serverPing_avg,
		convert(int, 0) as numChecks_avg
		into #serverResults
		from (
			select
				serverName, ymd,
				convert(decimal(10,2), dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 1), 10), 0)) as pingTime1,
				convert(decimal(10,2), dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 2), 10), 0)) as pingTime2,
				convert(decimal(10,2), dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 3), 10), 0)) as pingTime3,
				convert(decimal(10,2), dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 4), 10), 0)) as pingTime4

				from pingLog (nolock)
				where ymd >= dateAdd(hour, -@nNumHours, @dRightNow)
					and isnull(serverPingResults, '') <> ''
			) a
		group by serverName

	update #serverResults
		set serverPing_avg = b.serverPing,
			numChecks_avg = b.numChecks
		from #serverResults a
		join (
			select
				serverName,
				convert(decimal(10,2), avg(
					(
						case when isnull(pingTime1, 0) = 0 then 9999 else pingTime1 end +
						case when isnull(pingTime2, 0) = 0 then 9999 else pingTime2 end +
						case when isnull(pingTime3, 0) = 0 then 9999 else pingTime3 end +
						case when isnull(pingTime4, 0) = 0 then 9999 else pingTime4 end
						) / 4.00
					)) as serverPing,
				count(distinct ymd) as numChecks
				from (
					select
						serverName, ymd,
						convert(decimal(10,2), dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 1), 10), 0)) as pingTime1,
						convert(decimal(10,2), dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 2), 10), 0)) as pingTime2,
						convert(decimal(10,2), dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 3), 10), 0)) as pingTime3,
						convert(decimal(10,2), dbo.fn_returnDigits(substring(serverPingResults, dbo.fn_at(serverPingResults, 'time', 4), 10), 0)) as pingTime4

						from v_pingLog_all (nolock)
						where ymd < dateAdd(hour, -@nNumHours, @dRightNow)
							and ymd >= dateAdd(week, -6, @dRightNow)
							and isnull(serverPingResults, '') <> ''
					) a
				group by serverName
			) b on a.serverName = b.serverName

	select * from #serverResults

	drop table #serverResults

end
GO
