/****** Object:  StoredProcedure [dbo].[pr_proxyServiceIPList_get]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from dm_proxyService
-- exec pr_proxyServiceIPList_get 1, 1
-- exec pr_proxyServiceIPList_get 2
CREATE procedure [dbo].[pr_proxyServiceIPList_get] (@nUkeyProxyService int, @bIsPreview bit = 0)
as
begin

--	declare @nUkeyProxyService int = 1
--	declare @bIsPreview bit = 1
	declare @cLocation varchar(2000)
	declare @cFilePath varchar(500)
	declare @cSQLString nvarchar(4000)
	declare @nUkey int
	declare @cType varchar(100)
	declare @nSubnet int
	declare @cIPAddress varchar(15)
	declare @nMaxUkey int

	select top 1
		@cLocation = location,
		@cFilePath = filepath
		from dm_proxyService (nolock)
		where ukey = @nUkeyProxyService

	--drop table #results
	create table #results (widestring varchar(8000), ukey_proxyService int, [type] varchar(100), ipAddress varchar(100), subnet int, ukey int identity)

	--set @cSQLString = 'del "' + @cFilePath + '"'
	--insert into #results (widestring)
	--exec master..xp_cmdshell @cSQLString

	set @cSQLString = 'C:\temp\curl\bin\curl -o ' + @cFilePath + ' "' + @cLocation + '"'
	print @cSQLString
	insert into #results (widestring)
	exec master..xp_cmdshell @cSQLString

	truncate table #results
	set @cSQLString = 'type "' + @cFilePath + '"'
	print @cSQLString
	insert into #results (widestring)
	exec master..xp_cmdshell @cSQLString

	if isnull(@nUkeyProxyService, 0) = 1
	begin
		update #results
			set ukey_proxyService = @nUkeyProxyService,
				[type] = 'ipv4',
				ipAddress = substring(widestring, 1, charindex('/', widestring) -1),
				subnet = substring(widestring, charindex('/', widestring) + 1, len(widestring) - charindex('/', widestring))
			from #results
	end
--	select * from #results

	set @nUkey = 0
	set @nMaxUkey = (select max(ukey) from #results)

	delete from #results where [type] not like '%4%'

	while exists (select top 1 ukey from #results where @nUkey < ukey)
		and @nUkey < @nMaxUkey
	begin
		select top 1
			@nUkey = ukey,
			@cIPAddress = ipAddress,
			@cType = [type],
			@nSubnet = subnet
			from #results
			where @nUkey < ukey
			order by ukey

		--print 'exec pr_returnIPListfromCIDR ''' + @cIPAddress + ''', ' + convert(varchar(25), @nSubnet)
		insert into #results (ipAddress)
		exec pr_returnIPListfromCIDR @cIPAddress, @nSubnet

		update #results
			set [type] = @cType,
				subnet = @nSubnet,
				ukey_proxyService = @nUkeyProxyService
			where [type] is null

		delete from #results where ukey = @nUkey
	end

	if isnull(@bIsPreview, 0) = 0
	begin

		-- declare @nUkeyProxyService int = 1

		delete from proxyServiceIPList where ukey_proxyService is null or ipAddress is null

		delete a
		--select *
			from proxyServiceIPList a (nolock)
			left join #results b on a.ukey_proxyService = b.ukey_proxyService
				and a.ipAddress = b.ipAddress
				and a.subnet = b.subnet
			where a.ukey_proxyService = @nUkeyProxyService
				and b.ukey_proxyService is null

		-- declare @nUkeyProxyService int = 1
		insert into proxyServiceIPList (ukey_proxyService, [type], ipAddress, subnet)
		select a.ukey_proxyService, a.[type], a.ipAddress, a.subnet
			from #results a
		--select *
			left outer join proxyServiceIPList b on a.ukey_proxyService = b.ukey_proxyService
				and a.ipAddress = b.ipAddress
				and a.subnet = b.subnet
			where b.ukey is null
				and not a.ukey_proxyService is null
				and not a.ipAddress is null
	end
	else
	begin
		select * from #results
	end

	drop table #results
end
GO
