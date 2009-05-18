/****** Object:  StoredProcedure [dbo].[pr_rpt_fragmentation]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_fragmentation 'sqlcluster01', null, null
CREATE procedure [dbo].[pr_rpt_fragmentation] (@cServerName varchar(100))
as
begin

	declare @nUkeyServer int

	set @nUkeyServer = (select ukey from dm_servers (nolock) where serverName = @cServerName)

	select
		dbName, objectName, indexName,
		max(rows) as [rows],
		max(extents) as extents,
		max(extentSwitches) as extentSwitches,
		convert(decimal(10,2), min(scanDensity)) as scanDensity,
		max(convert(varchar(10), ymd, 120)) as ymd

		from fragmentationLog (nolock)
		where ukey_server = @nUkeyServer
			and ymd >= dateAdd(month, -2, getDate())
			and [rows] <> 0
		group by dbName, objectName, indexName
end
GO
