IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_fragmentation]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_fragmentation ''sqlcluster01'', null, null
CREATE procedure [pr_rpt_fragmentation] (@cServerName varchar(100))
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
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
