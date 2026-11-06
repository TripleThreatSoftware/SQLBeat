/****** Object:  StoredProcedure [dbo].[pr_searchEngineBotList_get]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_searchEngineBotList_get 1
-- exec pr_searchEngineBotList_get 2
CREATE procedure [dbo].[pr_searchEngineBotList_get] (@nUkeyEngine int, @bIsPreview bit = 0)
as
begin

	--declare @nUkeyEngine int = 1
	--declare @bIsPreview bit = 0
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
		from dm_searchEngine (nolock)
		where ukey = @nUkeyEngine

	--drop table #results
	create table #results (widestring varchar(8000), ukey_engine int, [type] varchar(100), ipAddress varchar(100), subnet int, ukey int identity)

	set @cSQLString = 'del "' + @cFilePath + '"'
	insert into #results (widestring)
	exec master..xp_cmdshell @cSQLString

	set @cSQLString = 'C:\temp\curl\bin\curl -o ' + @cFilePath + ' "' + @cLocation + '"'
	insert into #results (widestring)
	exec master..xp_cmdshell @cSQLString

	truncate table #results
	set @cSQLString = 'type "' + @cFilePath + '"'
	insert into #results (widestring)
	exec master..xp_cmdshell @cSQLString

	delete from #results where widestring not like '%ipv%' or widestring is null


	-- declare @nUkeyEngine int = 1
	update #results
		set ukey_engine = @nUkeyEngine,
			[type] = substring(widestring, patindex('%"ip%', widestring) +1, patindex('%": "%', widestring) - patindex('%"ip%', widestring) -1),
			ipAddress = substring(widestring, patindex('%": "%', widestring) +4, charindex('/', widestring) - patindex('%": "%', widestring) -4),
			subnet = case when charindex('/', reverse(widestring)) = 0 then null else replace(right(widestring, charindex('/', reverse(widestring)) - 1), '"', '') end
	--select *, right(widestring, charindex('/', reverse(widestring)))
		from #results



	if @nUkeyEngine in (2)
	begin
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
					ukey_engine = @nUkeyEngine
				where [type] is null

			delete from #results where ukey = @nUkey
		end
	end

	--select * from #results
	if isnull(@bIsPreview, 0) = 0
	begin

		-- declare @nUkeyEngine int = 1

		delete from searchEngineBotList where ukey_engine is null or ipAddress is null

		delete a
		--select *
			from searchEngineBotList a (nolock)
			left join #results b on a.ukey_engine = b.ukey_engine
				and a.ipAddress = b.ipAddress
				and a.subnet = b.subnet
			where a.ukey_engine = @nUkeyEngine
				and b.ukey_engine is null

		-- declare @nUkeyEngine int = 1
		insert into searchEngineBotList (ukey_engine, [type], ipAddress, subnet)
		select a.ukey_engine, a.[type], a.ipAddress, a.subnet
			from #results a
		--select *
			left outer join searchEngineBotList b on a.ukey_engine = b.ukey_engine
				and a.ipAddress = b.ipAddress
				and a.subnet = b.subnet
			where b.ukey is null
				and not a.ukey_engine is null
				and not a.ipAddress is null
	end
	else
	begin
		select * from #results
	end

	drop table #results
end
GO
