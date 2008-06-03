IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_sendMessage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE procedure [pr_sendMessage] (@cFrom varchar(100), @cTo varchar(500), @cSubject varchar(500), @cBody varchar(8000))
as
begin
	if isnull(@cFrom, '''') = ''''
		set @cFrom = (select top 1 settingValue from dm_settings where settingName = ''Default Email From'')

	if isnull(@cTo, '''') = '''' or @cTo = ''DBA''
		set @cTo = (select top 1 settingValue from dm_settings where settingName = ''Default Email To'')

	if not exists (select * from dbo.sysobjects where [name] = ''messagesSent'')
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

--	set @cTo = ''cole@triplethreatsoftware.com''
--	exec sp_send_cdosysmail @cFrom, @cTo, @cSubject, @cBody
end

'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
