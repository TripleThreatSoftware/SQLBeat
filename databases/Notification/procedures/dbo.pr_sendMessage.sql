CREATE procedure [dbo].[pr_sendMessage] (@cFrom varchar(100), @cTo varchar(500), @cSubject varchar(500), @cBody varchar(8000))
as
begin
	declare @cClientCode varchar(100)
	set @cClientCode = (select top 1 settingValue from dm_settings where settingName = 'Client Code')

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
			body varchar(8000)
		)
	END

	insert into messagesSent (recipient, sender, subject, body) values (@cTo, @cFrom, @cSubject, @cBody)

	exec sp_send_cdosysmail @cFrom, @cTo, @cSubject, @cBody

--	set @cTo = 'cole@triplethreatsoftware.com'
--	exec sp_send_cdosysmail @cFrom, @cTo, @cSubject, @cBody
end



GO
