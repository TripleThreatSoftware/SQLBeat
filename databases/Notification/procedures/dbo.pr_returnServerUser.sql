create PROCEDURE [dbo].[pr_returnServerUser] @ukey int
AS
BEGIN
	declare @username varchar(50) = isnull((select userName from dm_servers where ukey = @ukey),'')
	declare @WMIusername varchar(50) = isnull((select WMIuserName from dm_servers where ukey = @ukey),'')

	select @username as username, @wmiUsername as wmiusername
END
