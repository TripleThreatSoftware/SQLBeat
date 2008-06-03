IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_outages_detail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_outages_detail null, null
create procedure [pr_rpt_outages_detail] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
--	declare @dStartDate dateTime
--	declare @dEndDate dateTime

	set nocount on

	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(week, -1, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	declare @cSQLString nvarchar(4000)
	declare @cSourceString nvarchar(4000)
	declare @cServerName varchar(200)

	declare @results table (groupName varchar(200), serverName varchar(200), outageStart dateTime, outageStop dateTime, details varchar(200))

	set @cSourceString = ''
declare @outages table (serverName varchar(200), outageStart dateTime)
declare @websiteOutages table (ukey_url int, outageStart dateTime)

insert into @outages
select serverName, ymd as outageStart
	from [**SERVERNAME**].notification.dbo.v_pingLog_all
	where isServerPingable = 0
		and ymd >= '''''' + convert(varchar(10), @dStartDate, 120) + ''''''
		and ymd < dateAdd(day, 1, '''''' + convert(varchar(10), @dEndDate, 120) + '''''')

insert into @websiteOutages
select ukey_url, ymd as outageStart
	from [**SERVERNAME**].websiteMonitor.dbo.monitoredURLs_history a
	where a.ymd >= '''''' + convert(varchar(10), @dStartDate, 120) + ''''''
		and isAvailable = 0
		and a.ymd < dateAdd(day, 1, '''''' + convert(varchar(10), @dEndDate, 120) + '''''')

select d.groupName, a.*
	from (
		select a.serverName, min(a.outageStart) as outageStart, b.outageStop,
 			case
				when b.outageStop is null then ''''Offline''''
				else ''''Not PINGing for '''' + convert(varchar(20), convert(int, ceiling((convert(decimal(10,2), dateDiff(millisecond, min(a.outageStart), b.outageStop))/1000.00)/60.00))) + '''' minute(s)''''
				end as details
			from @outages a
			left outer join (
				select a.serverName, a.outageStart, min(b.ymd) as outageStop
					from @outages a
					join [**SERVERNAME**].notification.dbo.v_pingLog_all b on a.serverName = b.serverName
						and b.isServerPingable = 1
						and b.ymd > a.outageStart
					group by a.serverName, a.outageStart
				) b on a.serverName = b.serverName
					and a.outageStart = b.outageStart
			group by a.serverName, b.outageStop
		) a
	join [**SERVERNAME**].notification.dbo.dm_servers c on a.serverName = c.serverName
	join [**SERVERNAME**].notification.dbo.dm_serverGroups d on c.ukey_group = d.ukey
union
select distinct ''''Websites'''', c.friendlyName, min(a.outageStart) as outageStart, b.outageStop,
	case
		when b.outageStop is null then ''''Offline''''
		else ''''Not PINGing for '''' + convert(varchar(20), convert(int, ceiling((convert(decimal(10,2), dateDiff(millisecond, min(a.outageStart), b.outageStop))/1000.00)/60.00))) + '''' minute(s)''''
		end as details
	from @websiteOutages a
	left outer join (
		select a.ukey_url, a.outageStart, min(b.ymd) as outageStop
			from @websiteOutages a
			join [**SERVERNAME**].websiteMonitor.dbo.monitoredURLs_history b on a.ukey_url = b.ukey_url
				and b.isAvailable = 1
				and b.ymd > a.outageStart
			group by a.ukey_url, a.outageStart
		) b on a.ukey_url = b.ukey_url
			and a.outageStart = b.outageStart
	join [**SERVERNAME**].websiteMonitor.dbo.monitoredURLs c on a.ukey_url = c.ukey
		and c.isEnabled = 1

	group by c.friendlyName, b.outageStop
union
select d.groupName, a.*
	from (
		select left(substring(subject, charindex(''''with '''', subject) + 5, 99), charindex('''' '''', substring(subject, charindex(''''with '''', subject) + 5, 99)) - 1) as serverName,
			ymd as outageStart,
			null as outageStop,
			''''Point Outage'''' as details
			from [**SERVERNAME**].notification.dbo.v_notificationLog_all
			where
				serverName = @@serverName
				and subject like ''''%lost communication%''''
				and message not like ''''%transaction log%''''
				and message not like ''''%disk space%''''
				and ymd >= '''''' + convert(varchar(10), @dStartDate, 120) + ''''''
				and ymd < dateAdd(day, 1, '''''' + convert(varchar(10), @dEndDate, 120) + '''''')
		) a
	join [**SERVERNAME**].notification.dbo.dm_servers c on a.serverName = c.serverName
	join [**SERVERNAME**].notification.dbo.dm_serverGroups d on c.ukey_group = d.ukey
''

	set @cSQLString = replace(@cSourceString, ''[**SERVERNAME**].'', '''')

	insert into @results (groupName, serverName, outageStart, outageStop, details)
	exec sp_executeSQL @cSQLString

	set @cServerName = ''''

	while exists (select top 1 settingValue from notification..dm_settings where settingName = ''Sister server'' and settingValue > @cServerName)
	begin
		select top 1
			@cServerName = settingValue
			from notification..dm_settings
			where settingName = ''Sister server''
				and settingValue > @cServerName
			order by settingValue

		set @cSQLString = replace(@cSourceString, ''**SERVERNAME**'', @cServerName)

		insert into @results (groupName, serverName, outageStart, outageStop, details)
		exec sp_executeSQL @cSQLString
	end

	select *
		from @results
		order by groupName, serverName


end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
