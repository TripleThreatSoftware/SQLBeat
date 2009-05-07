/****** Object:  StoredProcedure [dbo].[pr_rpt_tableSizes]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_tableSizes 'sqlcluster01'
CREATE procedure [dbo].[pr_rpt_tableSizes] (@cServerName varchar(100))
as
begin
	set nocount on

	select databaseName, tableName,
		convert(bigint, rows) as rows,
		convert(bigint, reserved) as reserved,
		convert(bigint, data) as data,
		convert(bigint, indexSize) as indexSize,
		convert(bigint, unused) as unused
		from tableSizeLog
		where serverName = @cServerName
			and ymd = (select max(ymd) from tableSizeLog where serverName = @cServerName)
		order by databaseName, tableName
end
GO
