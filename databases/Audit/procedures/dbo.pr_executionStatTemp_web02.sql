/****** Object:  StoredProcedure [dbo].[pr_executionStatTemp_web02]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_executionStatTemp_web02]
as
begin
	select objID, databaseName, sqlString, null, null, null, executionCount
		from openQuery([web02], '
			select top 5000 objID, b.[name] as databaseName, useCounts as executionCount, left(sql, 1000) as sqlString
				from master.dbo.syscacheobjects a (nolock)
				join master.dbo.sysdatabases b (nolock) on a.dbID = b.dbID
				order by useCounts desc
				')
end
GO
