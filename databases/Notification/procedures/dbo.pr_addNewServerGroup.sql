CREATE PROCEDURE [dbo].[pr_addNewServerGroup] @groupName varchar(25), @isProduction bit
AS
BEGIN
	declare @returnString varchar(25)
	if not exists (select * from dm_serverGroups where groupName = @groupName)
		begin
			insert into dm_serverGroups (groupName, isProduction) values (@groupName, @isProduction)
			set @returnString = 'Success'
		End
	Else
		set @returnString = 'Group Name already exists. Try again!'
	Select @returnString as returnString
END
