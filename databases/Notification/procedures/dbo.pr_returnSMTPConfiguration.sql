/****** Object:  StoredProcedure [dbo].[pr_returnSMTPConfiguration]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_returnSMTPConfiguration]
as
begin
	declare @cServer varchar(200)
	declare @nPort int
	declare @cUserName varchar(200)
	declare @cPassword varchar(200)
	declare @bUseSSL bit

	set @cServer = (select settingValue from dm_settings where settingName = 'SMTP Server')
	set @nPort = (select settingValue from dm_settings where settingName = 'SMTP Port')
	set @cUserName = (select settingValue from dm_settings where settingName = 'SMTP User Name')
	set @cPassword = (select settingValue from dm_settings where settingName = 'SMTP Password')
	set @bUseSSL = (select case when settingValue = 1 then 1 else 0 end from dm_settings where settingName = 'SMTP SSL')

	select @cServer as serverName, @nPort as port, @cUserName as userName, @cPassword as password, @bUseSSL as useSSL, 1 as ukey
end
GO
