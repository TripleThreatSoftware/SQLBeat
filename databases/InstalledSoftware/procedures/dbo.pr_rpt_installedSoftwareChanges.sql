use [installedsoftware]
go

-- exec pr_rpt_installedSoftwareChanges '2008-02-01', '2008-06-20'
-- exec pr_rpt_installedSoftwareChanges

ALTER procedure [dbo].[pr_rpt_installedSoftwareChanges] (@dStartDate dateTime = null, @dEndDate dateTime = null)
as
begin

--	declare @dStartDate dateTime
--	declare @dEndDate dateTime

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -48, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	select ukey_server,
		min(case when a.ymd >= @dStartDate and a.ymd <= @dEndDate then a.ukey else null end) as ukey_lastRun,
		max(case when a.ymd >= @dStartDate and a.ymd <= @dEndDate then a.ukey else null end) as ukey_thisrun
		into #runHistory
		from runs a (nolock)
		join (select distinct ukey_run, ukey_server from runs_data (nolock) ) b on a.ukey = b.ukey_run
		group by b.ukey_server

	-- installed since last check
	select d.serverName, 'Installed' as details,
		b.programName, b.installDate, b.version

		into #changeHistory

		from #runHistory a
		join runs_data b on a.ukey_thisRun = b.ukey_run
			and a.ukey_server = b.ukey_server
		left outer join runs_data c on a.ukey_lastRun = c.ukey_run
			and a.ukey_server = c.ukey_server
			and (
				isnull(b.programName, '') = isnull(c.programName, '')
				and isnull(b.installDate, '') = isnull(c.installDate, '')
				and isnull(b.version, '') = isnull(c.version, '')
				)
		join notification..dm_servers d on a.ukey_server = d.ukey
		where c.ukey is null
			and a.ukey_lastRun is not null
	union
	-- removed since last check
	select d.serverName, 'Removed' as details,
		b.programName, b.installDate, b.version
		from #runHistory a
		join runs_data b on a.ukey_lastRun = b.ukey_run
			and a.ukey_server = b.ukey_server
		left outer join runs_data c on a.ukey_thisRun = c.ukey_run
			and a.ukey_server = c.ukey_server
			and (
				isnull(b.programName, '') = isnull(c.programName, '')
				and isnull(b.installDate, '') = isnull(c.installDate, '')
				and isnull(b.version, '') = isnull(c.version, '')
				)
		join notification..dm_servers d on a.ukey_server = d.ukey
			and d.installedSoftwareCheck = 1
			and d.isEnabled = 1
		where c.ukey is null
		order by d.serverName, details, b.programName

	select *,
		identity(int) as ukey
		into #results
		from #changeHistory

	declare @cThisMessage varchar(8000)
	declare @cThisSubject varchar(500)
	declare @cThisServer varchar(200)

	set @cThisServer = ''

	while exists (select top 1 ukey from #results where serverName > @cThisServer)
	begin
		select top 1 @cThisServer = serverName from #results where serverName > @cThisServer

		set @cThisMessage = char(13) +
			'The following items have changed since the last check' + char(13) + char(13) +
			left('Server' + space(15), 15) + ' ' +
			left('Details' + space(10), 10) + ' ' +
			left('Program' + space(50), 50) + ' ' +
			left('Date' + space(10), 10) + ' ' +
			left('Version' + space(20), 20) + ' ' + char(13) +

			replicate('=', 15) + ' ' +
			replicate('=', 10) + ' ' +
			replicate('=', 50) + ' ' +
			replicate('=', 10) + ' ' +
			replicate('=', 20) + ' ' + char(13)

		select
			@cThisMessage = @cThisMessage +
				left(isnull(serverName, '-') + space(15), 15) + ' ' +
				left(isnull(details, '-') + space(10), 10) + ' ' +
				left(isnull(programName, '-') + space(50), 50) + ' ' +
				left(isnull(installDate, '-') + space(10), 10) + ' ' +
				left(isnull(version, '-') + space(20), 20) + ' ' + char(13)
			from #results
			where serverName = @cThisServer

		set @cThisSubject = 'Installed software changes for ' + convert(varchar(10), getDate(), 120)

		print @cThisSubject
		print @cThisMessage

		insert into notification..notificationLog_stage (serverName, subject, message, severity, isInstalledSoftware) values (
			@cThisServer, @cThisSubject, @cThisMessage, 2, 1)

	end

	drop table #runHistory
	drop table #results
	drop table #changeHistory
end
-- select top 100 * from notification..notificationLog order by ukey desc
-- delete from notification..notificationLog where ukey in (29609,29608,29607)
