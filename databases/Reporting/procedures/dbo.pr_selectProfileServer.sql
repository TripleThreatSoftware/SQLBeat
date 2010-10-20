/****** Object:  StoredProcedure [dbo].[pr_selectProfileServer]    Script Date: 10/20/2010 11:53:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--create table databaseSelection (ukey int identity, ymd dateTime default getDate(), machineID varchar(100), ukey_server int, databaseName varchar(200))
--go
-- create table profileSelection (ukey int identity, ymd dateTime default getDate(), machineID varchar(100), ukey_profile int)


create procedure [dbo].[pr_selectProfileServer] (@cMachineID varchar(100), @nUkeyProfile int, @nUkeyServer int)
as
begin
	exec pr_selectProfile @cMachineID, @nUkeyProfile

	delete from serverSelection where machineID = @cMachineID and ukey_server <> @nUkeyServer
	delete from databaseSelection where machineID = @cMachineID and ukey_server <> @nUkeyServer
end
GO
