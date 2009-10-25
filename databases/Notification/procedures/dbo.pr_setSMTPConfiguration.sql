create procedure pr_setSMTPConfiguration (@cServerName varchar(200), @nPort int, @cUserName varchar(200), @cPassword varchar(200), @bUseSSL bit = 0)
as
begin
	if not exists (select top 1 ukey from dm_settings where settingName = 'SMTP Password')
		insert into dm_settings (settingName) values ('SMTP Password')
	if not exists (select top 1 ukey from dm_settings where settingName = 'SMTP Port')
		insert into dm_settings (settingName) values ('SMTP Port')
	if not exists (select top 1 ukey from dm_settings where settingName = 'SMTP Server')
		insert into dm_settings (settingName) values ('SMTP Server')
	if not exists (select top 1 ukey from dm_settings where settingName = 'SMTP User Name')
		insert into dm_settings (settingName) values ('SMTP User Name')
	if not exists (select top 1 ukey from dm_settings where settingName = 'SMTP SSL')
		insert into dm_settings (settingName) values ('SMTP SSL')

	update dm_settings
		set settingValue = @cServerName
		where settingName = 'SMTP Server'
	update dm_settings
		set settingValue = @nPort
		where settingName = 'SMTP Port'
	update dm_settings
		set settingValue = @cUserName
		where settingName = 'SMTP User Name'
	update dm_settings
		set settingValue = @cPassword
		where settingName = 'SMTP Password'
	update dm_settings
		set settingValue = case when @bUseSSL = 1 then '1' else '0' end
		where settingName = 'SMTP SSSL'

end
GO
