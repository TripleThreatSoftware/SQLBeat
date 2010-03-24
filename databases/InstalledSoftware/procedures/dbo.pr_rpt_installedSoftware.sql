USE [InstalledSoftware]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_installedSoftware]    Script Date: 03/24/2010 10:40:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_rpt_installedSoftware] (@nUkeyServer int = 0, @cServerName varchar(200) = '')
as
begin
	if isnull(@cServerName, '') <> '' and isnull(@nUkeyServer, 0) = 0
		set @nUkeyServer = (select top 1 ukey from notification.dbo.dm_servers (nolock) where serverName = @cServerName)

	if isnull(@cServerName, '') = '' and isnull(@nUkeyServer, 0) <> 0
		set @cServerName = (select top 1 serverName from notification.dbo.dm_servers (nolock) where ukey = @nUkeyServer)

	declare @nUkeyRun int
	declare @cSQLString nvarchar(4000)

	declare @results table (groupName varchar(100), serverName varchar(200), programName varchar(500), installDate varchar(100), version varchar(100))
--	create table #results (groupName varchar(100), serverName varchar(200), programName varchar(500), installDate varchar(100), version varchar(100))

	insert into @results (groupName, serverName, programName, installDate, version)
	select d.groupName, a.serverName, c.programName, c.installDate, c.version
		from notification..dm_servers a
		join (
			select ukey_server, max(ukey_run) as ukey_run
				from runs_data a
				group by ukey_server
			) b on a.ukey = b.ukey_server
		join runs_data c on b.ukey_server = c.ukey_server
			and b.ukey_run = c.ukey_run
		join notification..dm_serverGroups d on a.ukey_group = d.ukey

		where (a.ukey = @nUkeyServer or isnull(@nUkeyServer, 0) = 0)

--	set @cServerName = ''
--
--	while exists (select top 1 settingValue from notification..dm_settings where settingName = 'Sister server' and settingValue > @cServerName)
--	begin
--		select top 1
--			@cServerName = settingValue
--			from notification..dm_settings
--			where settingName = 'Sister server'
--				and settingValue > @cServerName
--			order by settingValue
--
--		set @cSQLString = '
--	select d.groupName, a.serverName, c.programName, c.installDate, c.version
--		from [' + @cServerName + '].notification.dbo.dm_servers a
--		join (
--			select ukey_server, max(ukey_run) as ukey_run
--				from [' + @cServerName + '].installedSoftware.dbo.runs_data a
--				group by ukey_server
--			) b on a.ukey = b.ukey_server
--		join [' + @cServerName + '].installedSoftware.dbo.runs_data c on b.ukey_server = c.ukey_server
--			and b.ukey_run = c.ukey_run
--		join [' + @cServerName + '].notification.dbo.dm_serverGroups d on a.ukey_group = d.ukey'
--
--		insert into @results (groupName, serverName, programName, installDate, version)
--		exec sp_executeSQL @cSQLString
--	end

	select *
		from @results
		order by groupName, serverName, programName

--	drop table #results
end
