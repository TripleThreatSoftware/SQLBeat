/****** Object:  StoredProcedure [dbo].[pr_rpt_unreachableServers]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_unreachableServers]
as
begin

	select serverName, wmiStatus
		from dm_servers (nolock)
		where wmiStatus <> 'success'
			or (configurationCheck = 0 or installedSoftwareCheck = 0 or eventLogCheck = 0)
		order by serverName

end
GO
