create procedure pr_returnDashboards (@cMachineID varchar(100))
as
begin
	select *
		from dm_dashboards
		where machineID = @cMachineID
		order by dashboardName
end
