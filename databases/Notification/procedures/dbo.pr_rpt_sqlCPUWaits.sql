-- exec pr_rpt_sqlCPUWaits '10.3.10.110', 720

ALTER procedure [dbo].[pr_rpt_sqlCPUWaits] (@cServerName varchar(100), @nNumHours int = 12)
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
