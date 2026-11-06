/****** Object:  StoredProcedure [dbo].[pr_stageRunData]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_stageRunData] (@cServerName varchar(200) = '', @cCounterName varchar(200) = '', @cKeyName varchar(200) = '', @cKeyValue varchar(8000) = '', @nInstance int = 0, @nUkeyGroup int = 0)
as
begin
	set nocount on
	insert into runs_stage (serverName, counterName, keyName, keyValue, instance, ukey_group) values (@cServerName, @cCounterName, @cKeyName, @cKeyValue, @nInstance, @nUkeyGroup)

end
GO
