/****** Object:  StoredProcedure [dbo].[pr_returnServerUser]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[pr_returnServerUser] @ukey int
AS
BEGIN
	declare @username varchar(50) = isnull((select userName from dm_servers where ukey = @ukey),'')
	declare @WMIusername varchar(50) = isnull((select WMIuserName from dm_servers where ukey = @ukey),'')

	select @username as username, @wmiUsername as wmiusername
END
GO
