-- Configuration
-- Notification
-- Audit


--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************
-- Set SQL2005 configuration options
--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************

if (@@version like '%sql server 2005%') or (@@version like '%sql server 2008%') or (@@version like '%sql server 2014%') or (@@version like '%sql server 2019%') or (@@version like '%sql server 2022%')
begin
	exec sp_configure 'show advanced options', 1
	reconfigure

	exec sp_configure 'xp_cmdshell', 1
	exec sp_configure 'Agent XPs', 1
	exec sp_configure 'Ole Automation Procedures', 1

	reconfigure
end


--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************
-- Add registry key for LOCAL alias
--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************

set nocount on

print 'Verifying SQLBEAT alias'

declare @cSQLString nvarchar(4000)
declare @cServerName varchar(100)

set @cServerName = @@servername

if charindex('\', @cServerName) > 0
	set @cServerName = @cServerName
else
	set @cServerName = '(local)'

create table #results (resultLine varchar(8000))

set @cSQLString = 'reg query HKLM\Software\Microsoft\MSSQLServer\Client\ConnectTo /v SQLBEAT'

insert into #results (resultLine)
exec master..xp_cmdshell @cSQLString

if (select count(*) from #results where resultLine like '%ERROR%') > 0
begin
	-- assume the key doesn't exist, or needs to be overwritten
	set @cSQLString = 'reg add HKLM\Software\Microsoft\MSSQLServer\Client\ConnectTo /v SQLBEAT /t REG_SZ /d DBMSSOCN,' + @cServerName + ' /f'

	truncate table #results

	insert into #results (resultLine)
	exec master..xp_cmdshell @cSQLString

	print 'Creating SQLBEAT alias'
end
else
	print 'SQLBEAT alias already exists'

drop table #results
go

--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************
-- local user account

if (select count(*) from master.dbo.syslogins where name = 'sqlnotification') = 0
begin
	EXEC master.dbo.sp_addlogin @loginame = N'sqlnotification', @passwd = 'REDACTED', @defdb = N'notification', @deflanguage = N'us_english'

	USE [msdb]
	CREATE USER [sqlnotification] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
	EXEC sp_addrolemember N'db_owner', N'sqlnotification'
	EXEC master..sp_addsrvrolemember @loginame = N'sqlnotification', @rolename = N'sysadmin'
	use [notification]
end
go

--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************

-- basic settings
use notification
go

truncate table dm_settings

declare @cServerName varchar(200)
set @cServerName = @@servername

if charindex('\', @cServerName) > 0
begin
	set @cServerName = left(@cServerName, charindex('\', @cServerName) - 1)
end


insert into dm_settings (settingName, settingValue) values ('Job Owner', 'sa')
insert into dm_settings (settingName, settingValue) values ('Long running query threshold', '60')
insert into dm_settings (settingName, settingValue) values ('Current machine name', @cServerName)
insert into dm_settings (settingName, settingValue) values ('Current running user', 'sa')
insert into dm_settings (settingName, settingValue) values ('Page Life Expectancy Window Minutes', '10')
insert into dm_settings (settingName, settingValue) values ('Page Life Expectancy Low Threshold', '300')
insert into dm_settings (settingName, settingValue) values ('Shared Folder', 'C:\SHARED')
insert into dm_settings (settingName, settingValue) values ('Shared Folder Local Path', 'C:\SHARED')
go

--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************
-- configure emailing

declare @cAdminEmail varchar(100)
set @cAdminEmail = 'cole@sqlbeat.com'

insert into dm_settings (settingName, settingValue) values ('SMTP Server', '127.0.0.1')
insert into dm_settings (settingName, settingValue) values ('SMTP User Name', '')
insert into dm_settings (settingName, settingValue) values ('SMTP Password', '')
insert into dm_settings (settingName, settingValue) values ('SMTP Port', '25')
insert into dm_settings (settingName, settingValue) values ('SMTP SSL', '')
insert into dm_settings (settingName, settingValue) values ('Default Email From', @cAdminEmail)
insert into dm_settings (settingName, settingValue) values ('Default Email To', @cAdminEmail)
insert into userEmails (userName, emailAddress) values ('DBA', @cAdminEmail)
insert into messageRules (userName, ukey_userEmail, sendMessage) values ('DBA', 1, 1)
go

--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************
-- target server setup
firewall rule allowing eventlog wmi query


--****************************************************************************************************************************
--****************************************************************************************************************************
--****************************************************************************************************************************
-- server setup

insert into dm_serverGroups (groupName, isProduction) values ('Production Servers', 1)


select * from dm_serverGroups
select * from dm_servers

-- INSERT into dm_servers

exec pr_configureForType 'web02', 'SQL Server'
exec pr_configureForType 'web02', 'IIS Web Server'

-- how is this done before the linked server?
update dm_servers set username = 'sa', password = 'REDACTED', wmiUserName = 'cole', wmiPassword = 'REDACTED' where serverName = 'web02'
update dm_servers set ukey_group = (select top 1 ukey from dm_serverGroups where groupName = 'Production Servers')

insert into dm_settings (settingName, settingValue) values ('Respect Maintenance Window Setting', 0)

-- increase job history size
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=999999,
		@jobhistory_max_rows_per_job=100000
GO


select * from processlog
-- select * from pinglog
select * from tableSizeLog
select * from indexPerformanceLog
select * from fragmentationLog
select * from serviceLog
-- select * from performanceLog
-- select * from integrityLog
-- select * from databaseFileSizeLog
-- select * from filePerformance -- working
select * from drivespaceLog
select * from eventlog
select * from notificationLog order by ymd desc
select * from notificationLog_stage
-- select * from sqlErrorLog
select * from audit.dbo.auditData_objectText

select top 1000 * from notificationLog_history order by ymd desc

delete from notificationLog_stage where subject like '%exampleuser%'
delete from notificationLog_stage where subject like '%unable to perform integrity%'


select * from dm_settings

sp_who2
