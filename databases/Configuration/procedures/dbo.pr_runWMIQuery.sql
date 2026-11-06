/****** Object:  StoredProcedure [dbo].[pr_runWMIQuery]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_runWMIQuery] (@cServerName varchar(100), @cUserName varchar(100), @cPassword varchar(100), @cQuery varchar(4000))
as
begin

	declare @cSQLString nvarchar(4000)
	declare @cScriptPath varchar(500) = 'c:\shared\'

	declare @nUkey int = 0
	declare @cWideString varchar(max)
	declare @cKeyName varchar(500)
	declare @cKeyValue varchar(max)
	declare @cObjectName varchar(500)
	declare @nCounter int = 0

	--declare @cServerName varchar(100) = 'appweb34'
	--declare @cUserName varchar(100) = 'MonitoringService'
	--declare @cPassword varchar(100) = 'REDACTED'
	--declare @cQuery varchar(500)

	if object_id('tempdb..#output') is not null
		drop table #output
	create table #output (widestring varchar(max), ukey int identity)
	create index ix_tmp_output_ukey on #output (ukey) with fillfactor = 60

	--set @cQuery = 'select * from Win32_PerfFormattedData_APPPOOLCountersProvider_APPPOOLWAS where name = ""AppSecure""'
	--set @cQuery = 'select * from Win32_PerfFormattedData_W3SVC_WebService where name = ""AppSecure""'
	--set @cQuery = 'select * from Win32_PerfFormattedData_NETDataProviderforSqlServer_NETDataProviderforSqlServer'

	set @cSQLString = 'powershell -file ' + @cScriptPath + 'runQuery.ps1 -cServerName ' + @cServerName + ' -cUserName "' + @cUsername + '" -cPassword "' + @cPassword + '" -cQuery "' + @cQuery + '"'
	insert into #output (widestring)
	exec master..xp_cmdshell @cSQLString


	while exists (select top 1 ukey from #output where ukey > @nUkey and wideString is not null)
	begin
		select top 1 @nUkey = ukey, @cWideString = widestring from #output where ukey > @nUkey and wideString is not null order by ukey
		set @nCounter = @nCounter + 1

		if @cWideString = '**********'
		begin
			select top 1 @cWideString = widestring from #output where ukey = @nUkey-1
			set @cObjectName = @cWideString
			set @cKeyName = ''
			set @cKeyValue = ''
			set @nCounter = 0
		end
		else
		if @cWideString = '*/*/*'
		begin
			insert into #results (objectName, keyName, keyValue) values (@cObjectName, @cKeyName, @cKeyValue)
			set @cKeyName = ''
			set @cKeyValue = ''
			set @nCounter = 0
		end
		else
		begin
			if @nCounter = 1
				set @cKeyName = @cWideString
			else
				set @cKeyValue = @cKeyValue + @cWideString
		end
	end

	insert into #results (objectName, keyName, keyValue) values (@cObjectName, @cKeyName, @cKeyValue)

	if object_id('tempdb..#output') is not null
		drop table #output
end
GO
