/****** Object:  StoredProcedure [dbo].[pr_returnProfileList]    Script Date: 10/20/2010 11:53:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_returnProfileList] (@cMachineID varchar(100))
as
begin
	declare @results table (ukey int, profileName varchar(200))

	insert into @results (ukey, profileName) values (0, 'All Servers')

	insert into @results (ukey, profileName)
	select ukey, profileName
		from dm_profiles
		where machineID = @cMachineID
		order by profileName

	select * from @results order by ukey
end
GO
