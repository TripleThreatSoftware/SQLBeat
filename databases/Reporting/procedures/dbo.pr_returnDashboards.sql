/****** Object:  StoredProcedure [dbo].[pr_returnDashboards]    Script Date: 10/20/2010 11:53:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_returnDashboards] (@cMachineID varchar(100))
as
begin
	select *
		from dm_dashboards
		where machineID = @cMachineID
		order by dashboardName
end
GO
