/****** Object:  StoredProcedure [dbo].[pr_rpt_sqlCPUWaits]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_sqlCPUWaits '10.3.10.110', 720

CREATE procedure [dbo].[pr_rpt_sqlCPUWaits] (@cServerName varchar(100), @nNumHours int = 12)
as
begin

	select serverName, 'CPU ' + convert(varchar(20), cpuNumber) as subkeyName, numTasksWaiting, ymd
		from deepSQLStats_cputasks (nolock)
		where
			(serverName = @cServername or isnull(@cServerName, '') = '')
			and ymd >= dateAdd(hour, -@nNumHours, getdate())
			and numTasksWaiting > 0
		order by serverName, ymd, subkeyName



end
GO
