use scheduler
go
--select top 100 * from monitoredURLs_history order by ymd desc
--select * from monitoredURLs
create procedure pr_monitorURLs
as
begin
	set nocount on

	declare @cScriptPath varchar(500)
	declare @cLocalFile varchar(500)
	declare @cURL varchar(2000)
	declare @cSQLString nvarchar(4000)
	declare @cWebpageText varchar(8000)
	declare @nUkeyURL int
	declare @cMatchString varchar(800)
	declare @dStartTime dateTime
	declare @dEndTime dateTime
	declare @bIsAvailable bit

	set @nUkeyURL = 0

	create table #results (wideString varchar(500))
	create table ##webpage (widestring varchar(8000))

	set @cScriptPath = (select top 1 settingValue from notification.dbo.dm_settings where settingName = 'shared folder')

	if right(@cScriptPath, 1) <> '\'
		set @cScriptPath = @cScriptPath + '\'

	set @cLocalFile = @cScriptPath + 'download.htm'

	while exists (select top 1 ukey from monitoredURLs where isEnabled = 1 and ukey > @nUkeyURL)
	begin
		select top 1
			@nUkeyURL = ukey,
			@cURL = websiteURL,
			@cMatchString = matchString
			from monitoredURLs
			where isEnabled = 1
				and ukey > @nUkeyURL
			order by ukey

		truncate table #results
		truncate table ##webpage
		set @cSQLString = 'powershell -file ' + @cScriptPath + 'downloadURL.ps1 -cURL "' + @cURL + '" -cLocalFile "' + @cLocalFile + '"'

		set @dStartTime = getDate()
		insert into #results (wideString)
		exec master..xp_cmdshell @cSQLString

		set @dEndTime = getDate()

		truncate table ##webpage
		set @cSQLString = '
			bulk insert ##webpage
				from ''' + @cLocalFile + '''
				WITH
				(
					FIRSTROW = 1,
					LASTROW = 100,
					ROWTERMINATOR =''\n'',
					MAXERRORS = 1000
				)'

		begin try
			insert into #results (wideString)
			exec sp_executeSQL @cSQLString
		end try
		begin catch

		end catch

		set @cSQLString = 'del ' + @cLocalFile

		insert into #results (wideString)
		exec master..xp_cmdshell @cSQLString

		set @cWebpageText = ''

		select @cWebpageText = left(@cWebpageText + isnull(wideString, ''), 8000)
			from ##webpage

		if @cWebpageText like '%' + @cMatchString + '%'
			set @bIsAvailable = 1
		else
			set @bIsAvailable = 0

		insert into monitoredURLs_history (message, ukey_url, isAvailable, startTime, endTime) values (left(@cWebpageText, 800), @nUkeyURL, @bIsAvailable, @dStartTime, @dEndTime)
		update monitoredURLs set lastCheck = getDate() where ukey = @nUkeyURL

	end

	drop table #results
	drop table ##webpage
end
