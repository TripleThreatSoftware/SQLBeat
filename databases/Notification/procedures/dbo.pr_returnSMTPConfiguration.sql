USE [notification]
GO

/****** Object:  StoredProcedure [dbo].[pr_returnSMTPConfiguration]    Script Date: 06/18/2012 10:26:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[pr_returnSMTPConfiguration]
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

	select @cServer as serverName, isnull(@nPort, 25) as port, isnull(@cUserName, '') as userName, isnull(@cPassword, '') as password, isnull(@bUseSSL, 0) as useSSL, 1 as ukey
end

GO
