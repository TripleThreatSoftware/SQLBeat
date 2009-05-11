create procedure pr_add_log (@Message varchar(500) = null, @Server varchar(100) = null)
as begin
	set nocount on;
	insert runs_log (message, serverName) values (@Message, @Server);
end;
GO
select * from installedSoftware..v_ready_queue

drop view v_ready_queue
GO
