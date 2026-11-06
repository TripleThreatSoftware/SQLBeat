/****** Object:  StoredProcedure [dbo].[pr_sendMessage]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--declare @cMessage varchar(8000)
--set @cMessage = 'this' + char(13) + 'is a test'
--exec pr_sendMessage '', 'DBA', 'Test message', @cMessage, 1

CREATE procedure [dbo].[pr_sendMessage] (@cFrom varchar(100), @cTo varchar(500), @cSubject varchar(2000), @cBody varchar(max), @bSendHTML bit = 1)
as
begin
	declare @cClientCode varchar(100)
	set @cClientCode = (select top 1 settingValue from dm_settings where settingName = 'Client Code')

	if isnull(@cClientCode, '') <> ''
		set @cSubject = '[' + @cClientCode + '] ' + @cSubject

	if isnull(@cFrom, '') = ''
		set @cFrom = (select top 1 settingValue from dm_settings where settingName = 'Default Email From')

	if isnull(@cTo, '') = '' or @cTo = 'DBA'
		set @cTo = (select top 1 settingValue from dm_settings where settingName = 'Default Email To')

	if not exists (select * from dbo.sysobjects where [name] = 'messagesSent')
	BEGIN
		CREATE TABLE messagesSent (
			ukey int identity,
			ymd dateTime default getDate(),
			recipient varchar(100),
			sender varchar(100),
			subject varchar(500),
			body varchar(max)
		)
	END

	if @bSendHTML = 1
	begin
		set @cBody = '<div style="font-family:Courier; font-size: x-small;">' + replace(@cBody, char(13), '<br>') + '</div>' + '
<hr>
<div style="font-family:Verdana; font-size:x-small; margin:0;">SQLBeat on ' + @@servername + '</div>'


		exec sp_send_cdosysmail @cFrom, @cTo, @cSubject, '', '', @cBody
	end
	else
		exec sp_send_cdosysmail @cFrom, @cTo, @cSubject, @cBody

end
GO
