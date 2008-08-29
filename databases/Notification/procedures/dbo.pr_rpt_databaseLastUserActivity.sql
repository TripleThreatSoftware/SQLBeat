use [notification]
GO

ALTER procedure [dbo].[pr_rpt_databaseLastUserActivity] (@cServerName varchar(200))
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
					and ymd >= dateAdd(month, -1, getDate())
				group by dbName
			) c on a.dbname = c.dbName
		where a.dbName not in ('master', 'model', 'msdb', 'distribution', 'tempdb')
		order by a.dbName

end
