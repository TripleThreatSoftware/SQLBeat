SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[pr_returnLastAddedServerGroup]
AS
BEGIN
	declare @lastAddedUkey int
	set @lastAddedUkey = (Select top 1 [ukey] from dm_serverGroups order by ukey desc)
	select @lastAddedUkey as lastAddedUkey
END
