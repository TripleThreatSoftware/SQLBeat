create procedure pr_stageRunData (@cServerName varchar(200) = '', @cCounterName varchar(200) = '', @cKeyName varchar(200) = '', @cKeyValue varchar(8000) = '', @nInstance int = 0, @nUkeyGroup int = 0)
as
begin
	set nocount on
	insert into runs_stage (serverName, counterName, keyName, keyValue, instance, ukey_group) values (@cServerName, @cCounterName, @cKeyName, @cKeyValue, @nInstance, @nUkeyGroup)

end
GO
