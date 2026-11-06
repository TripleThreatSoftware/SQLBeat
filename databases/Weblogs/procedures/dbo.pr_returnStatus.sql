/****** Object:  StoredProcedure [dbo].[pr_returnStatus]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_returnStatus]
as
begin
	select 'All is well' + '<br>' +
		@@servername as statusString


	--declare @cSQLString nvarchar(4000)
	--declare @cDatabaseName varchar(100)
	--declare @jobID uniqueIdentifier
	--declare @cBody varchar(500)
	--declare @databaseList table (databaseName varchar(100))

	--insert into @databaseList (databaseName)
	--select [name]
	--	from master..sysdatabases
	--	where databasepropertyex([name], 'IsInStandby') = 1
	--		or databasepropertyex([name], 'Status') in ('Restoring', 'Recovering')

	--set nocount on

	--delete from @databaseList where ISNULL(databaseName, '') = ''

	--if (select COUNT(*) from @databaseList) > 0
	--	and (select COUNT(*) from @databaseList where databaseName = 'AppDb') = 1
	--begin
	--	-- CRAP. We have a failover.

	--	exec msdb.dbo.sp_start_job @job_name = 'Initiate Failover'

	--end
end
GO
