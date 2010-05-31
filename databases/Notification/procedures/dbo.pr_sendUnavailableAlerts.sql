SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_sendUnavailableAlerts]
as
begin
	declare @cThisMessage varchar(4000)
	declare @cThisSubject varchar(500)
	declare @cFriendlyName varchar(500)
	declare @nUkey int
	declare @nUkeyURL int
	declare @dFailure dateTime

	select a.friendlyName, a.websiteURL, c.isAvailable, c.ymd, c.message, identity(int) as ukey, a.ukey as ukey_url
		into #results
		from monitoredURLs a
		join (
			select ukey_url,
				max(ymd) as ymd
				from monitoredURLs_history
				where ymd >= dateAdd(minute, -30, getDate())
				group by ukey_url
			) b on a.ukey = b.ukey_url
		join monitoredURLs_history c on b.ukey_url = c.ukey_url
			and b.ymd = c.ymd
			and c.isAvailable = 0
		order by a.friendlyName

	set @nUkey = 0

	while exists (select top 1 ukey from monitoredURLs (nolock) where ukey not in (select distinct ukey_url from #results) and ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@cFriendlyName = friendlyName
			from monitoredURLs (nolock)
			where ukey not in (select distinct ukey_url from #results)
				and ukey > @nUkey
			order by ukey

		print @cFriendlyName + ' is up!'

		exec notification..pr_updateState @cKeyName = @cFriendlyName, @cState = 'Up', @cCategory = 'WebsiteMonitor', @bIsGood = 1
	end

	set @nUkey = 0


	--ALTER procedure [dbo].[pr_updateState] (@cKeyName varchar(500), @cState varchar(200), @dYMD dateTime = '', @cCategory varchar(200) = 'Uncategorized', @bIsGood bit = 1)

	while exists (select top 1 ukey from #results where ukey > @nUkey order by ukey)
	begin
		select top 1
			@cThisSubject = 'URL ' + friendlyName + ' is unavailable at ' + right(left(convert(varchar(40), ymd, 120), 16), 5) + '.',
			@cThisMessage = 'URL ' + friendlyName + ' (' + websiteURL + ') is returning: ' + char(13) +
				isnull(message, 'N/A'),
			@nUkey = ukey,
			@cFriendlyName = friendlyName,
			@nUkeyURL = ukey_url,
			@dFailure = ymd
			from #results
			where ukey > @nUkey
			order by ukey

		if (select isnull(max(ymd), dateAdd(minute, -20, getDate())) from monitoredURLs_history where isAvailable = 1 and ukey_url = @nUkeyURL) < dateAdd(minute, -60, getDate())
		begin
			update monitoredURLs set isEnabled = 0 where ukey = @nUkeyURL

			set @cThisSubject = 'URL ' + @cFriendlyName + ' has been offline for more than 60 minutes. Disabling further checks of this URL.'
			set @cThisMessage = 'URL ' + @cFriendlyName + ' has been offline for more than 60 minutes. Disabling further checks of this URL.'
		end

		exec notification..pr_updateState @cKeyName = @cFriendlyName, @cState = 'Down', @dYMD = @dFailure, @cCategory = 'WebsiteMonitor', @bIsGood = 0

		insert into notification..notificationLog_stage (serverName, subject, message, severity, isConnectivity) values (
			@cFriendlyName, @cThisSubject, @cThisMessage, 1, 1)
	end

	drop table #results
end
