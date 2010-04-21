SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_blockData_outages '2s4zlb555jayq223jisrkt3n'
create procedure [dbo].[pr_rpt_blockData_diskPerformance] (@cMachineID varchar(100))
as
begin

	select
		a.serverName + ' @ ' + right(convert(varchar(20), a.ymd, 120), 8) as keyName,
		left(a.message, 200) as keyValue_string,
		'' as keyValue_numeric
		from notification..notificationLog a (nolock)
		join notification..dm_servers b (nolock) on a.serverName = b.serverName
		join serverSelection c on b.ukey = c.ukey_server
			and c.machineID = @cMachineID
		where (a.subject like '%queue%')
			and a.ymd >= dateAdd(hour, -24, getDate())
		order by a.ymd desc

end
