/****** Object:  StoredProcedure [dbo].[pr_rpt_databaseLastUserActivity]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_databaseLastUserActivity] (@cServerName varchar(200))
as
begin

	select a.dbName,
		isnull(b.ymd, c.ymd) as ymd
		from (
			select dbName, max(ymd) as ymd
				from databaseFileSizeLog (nolock)
				where serverName = @cServerName
				group by dbName
			) a
		left outer join (
			select dbname, max(ymd) as ymd
				from processLog (nolock)
				where serverName = @cServerName
					and hostName <> @@servername
					and hostname <> (select settingValue from dm_settings where settingName = 'current machine name')
				group by dbName
			) b on a.dbname = b.dbName
		left outer join (
			select dbname, max(ymd) as ymd
				from v_processLog_all (nolock)
				where serverName = @cServerName
					and hostName <> @@servername
					and hostname <> (select settingValue from dm_settings where settingName = 'current machine name')
					and ymd >= dateAdd(week, -2, getDate())
				group by dbName
			) c on a.dbname = c.dbName
		where a.dbName not in ('master', 'model', 'msdb', 'distribution', 'tempdb')
		order by a.dbName

end
GO
