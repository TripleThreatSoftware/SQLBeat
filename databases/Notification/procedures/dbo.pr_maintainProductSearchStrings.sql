ALTER procedure [dbo].[pr_maintainProductSearchStrings]
as
begin
	declare @dStartDate dateTime

	set @dStartDate = GETDATE()

	if exists (select top 1 [name] from sysobjects where [name] = 'lk_productSearchStrings_stage')
		drop table lk_productSearchStrings_stage

	create table lk_productSearchStrings_stage (ukey_website int, ukey_product int, searchString varchar(8000), searchString_lowPriority varchar(8000), searchString_nospaces varchar(8000), ukey int identity,
		lastModified dateTime default getDate()
--		, string_checksum bigint
		)
	create clustered index ix_productSearchStringsStage_website_product on lk_productSearchStrings_stage (ukey_website, ukey_product) with fillfactor = 90

	-- added the special note here so that JCW items with specialNote values are included in the high priority search string
	insert into lk_productSearchStrings_stage (ukey_website, ukey_product, searchString, searchString_lowPriority)
	select
		ukey_website,
		ukey,
		isnull(rtrim(ltrim(productDescription)) + ' ', '') + isnull(rtrim(ltrim(specialNote)), ''),
		isnull(rtrim(ltrim(productApplication)) + ' ', '') + ISNULL(rtrim(ltrim(manufacturer)), '')
		from products (nolock)
		where [enabled] = 1

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': Built base table'

	create table #productStrings_pre (ukey_website int, ukey_product int, productString varchar(8000))
	create table #productStrings (ukey_website int, ukey_product int, productString varchar(8000), stringNumber int default 0, ukey int identity)

--	insert into #productStrings_pre (ukey_website, ukey_product, productString)
--	select distinct
--		b.ukey_website,
--		b.ukey_product,
--		rtrim(ltrim(isnull(rtrim(ltrim(c.assemblyName)) + ' ', '') + isnull(rtrim(ltrim(replace(applicationNotes, '<br>', ' '))) + ' ', '')))
--		from assemblies c (nolock)
--		join assemblyProducts b (nolock) on c.ukey = b.ukey_assembly
--			and c.ukey_website = b.ukey_website
----		where c.ukey_website = 14 and ukey_product = 1046389
--		option (maxdop 3)

	insert into #productStrings_pre (ukey_website, ukey_product, productString)
	select distinct
		ukey_website,
		ukey_product,
		isnull(rtrim(ltrim(replace(replace(replace(applicationNotes, '<br>', ' '), 'Requires:', ''), 'Required:', ''))) + ' ', '')
		from assemblyProducts (nolock)
		where ISNULL(applicationNotes, '') <> ''
		option (maxdop 3)

	insert into #productStrings_pre (ukey_website, ukey_product, productString)
	select distinct
		c.ukey_website,
		b.ukey_product,
		isnull(rtrim(ltrim(c.assemblyName)) + ' ', '')
		from assemblies c (nolock)
		join assemblyProducts b (nolock) on c.ukey = b.ukey_assembly
			and c.ukey_website = b.ukey_website
		option (maxdop 3)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': assembly names and application notes added to LP'

	insert into #productStrings_pre (ukey_website, ukey_product, productString)
	select distinct b.ukey_website, b.ukey_product, isnull(rtrim(ltrim(d.imageTitle)) + ' ', '') + isnull(rtrim(ltrim(d.imageDescription)) + ' ', '')
		from assemblyProducts b (nolock)
		join assemblyImages d (nolock) on b.ukey_assembly = d.ukey_assembly
			and d.ukey_website = b.ukey_website
			and (
				isnull(d.imageTitle, '') <> ''
				or isnull(d.imageDescription, '') <> ''
				)
		option (maxdop 3)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': assembly images added to LP'

	insert into #productStrings_pre (ukey_website, ukey_product, productString)
	select distinct b.ukey_website, b.ukey_product, isnull(rtrim(ltrim(c.optionValue)) + ' ', '')
		from productOptions b (nolock)
		join dm_optionValues c (nolock) on b.ukey_optionValue = c.ukey
			and b.ukey_option = c.ukey_option
			and b.ukey_website = b.ukey_website
		option (maxdop 3)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': productOptions added to LP'

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': productStrings_pre table built'

	insert into #productStrings (ukey_website, ukey_product, productString)
	select ukey_website, ukey_product, productString
		from #productStrings_pre
		order by LEN(productString), productString

	drop table #productStrings_pre

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': productStrings table built'

	create clustered index ix_tmp_productStrings_website_product on #productStrings (ukey_website, ukey_product, ukey) with fillfactor = 80
--	create index ix_tmp_productStrings_website_product_stringNumber_ukey_productString on #productStrings (ukey_website, ukey_product) include (stringNumber, ukey, productString) with fillfactor = 80

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': LP string table indexed'

	set nocount on

	declare @bContinue bit
	declare @nCounter int

	set @bContinue = 1
	set @nCounter = 1

	while @bContinue = 1 and @nCounter <= 100
	begin

		update #productStrings with (tablock)
			set stringNumber = @nCounter --b.maxInstance + 1
			from #productStrings a
			join (
				select
					ukey_website,
					ukey_product,
					min(ukey) as ukey
--					, isnull(max(isnull(stringNumber, 0)), 0) as maxInstance
					from #productStrings (nolock)
					where isnull(stringNumber, 0) = 0
					group by ukey_website, ukey_product
--					having sum(case when stringNumber = 0 or stringNumber is null then 1 else 0 end) > 0
			) b on a.ukey_website = b.ukey_website
				and a.ukey_product = b.ukey_product
				and a.ukey = b.ukey

		if @@rowcount = 0
			set @bContinue = 0

		set @nCounter = @nCounter + 1
	end

print convert(varchar(20), @nCounter) + ' iterations'

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': LP string numbers assigned'

	create index ix_tmp_productStrings_website_product_stringNumber on #productStrings (ukey_website, ukey_product, stringNumber) include (productString) with fillfactor = 80
	create index ix_tmp_productStrings_stringNumber_website_product on #productStrings (stringNumber, ukey_website, ukey_product) include (productString) with fillfactor = 80

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': #productStrings table indexed'

	set @nCounter = 1

	while @nCounter <= (select MAX(stringNumber) from #productStrings)
	begin

		update lk_productSearchStrings_stage with (tablock)
			set searchString_lowPriority = isnull(searchString_lowPriority + ' ', '') + isnull(productString, '')
			from lk_productSearchStrings_stage a
			join #productStrings b (nolock) on a.ukey_product = b.ukey_product
				and b.ukey_website = a.ukey_website
				and b.stringNumber = @nCounter
			option (maxdop 3)

		set @nCounter = @nCounter + 1
	end

	set nocount off

print convert(varchar(20), @nCounter) + ' iterations'

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': LP strings assigned'

	drop table #productStrings

	update lk_productSearchStrings_stage with (tablock)
		set searchString_lowPriority = isnull(searchString_lowPriority + ' ', '') + b.categoryList
		from lk_productSearchStrings_stage a
		join lk_productCategories b (nolock) on a.ukey_product = b.ukey_product
			and b.ukey_website = a.ukey_website
		option (maxdop 3)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': Categories LP string'

	create index ix_productSearchStringsStage_product_inc_website_search1_search2 on lk_productSearchStrings_stage (ukey_product) include (ukey_website, searchString, searchString_lowPriority) with fillfactor = 80

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': Index made'

	select
		a.searchString,
		dbo.fn_returnLettersAndNumbers(dbo.fn_removeAllPunctuation(a.searchString)) as searchString_trimmed
		into #stringList1
		from (
			select distinct searchString
				from lk_productSearchStrings_stage (nolock)
				where searchString_lowPriority is not null
			) a
		option (maxdop 3)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': Searchstring trimmed'

	select
		a.searchString_lowPriority,
		dbo.fn_returnLettersAndNumbers(dbo.fn_removeAllPunctuation(searchString_lowPriority)) as searchStringLowPriority_trimmed
		into #stringList2
		from (
			select distinct
				searchString_lowPriority
				from lk_productSearchStrings_stage (nolock)
				where searchString_lowPriority is not null
			) a
		option (maxdop 3)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': LP search string trimmed'

	update lk_productSearchStrings_stage with (tablock)
		set searchString = b.searchString_trimmed,
			searchString_nospaces = left(replace(b.searchString_trimmed, ' ', ''), 8000)
		from lk_productSearchStrings_stage a
		join #stringList1 b on a.searchString = b.searchString
		option (maxdop 3)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': SearchString set'

	update lk_productSearchStrings_stage with (tablock)
		set searchString_lowPriority = b.searchStringLowPriority_trimmed,
			searchString_nospaces = left(a.searchString_nospaces + replace(b.searchStringLowPriority_trimmed, ' ', ''), 8000)
		from lk_productSearchStrings_stage a
		join #stringList2 b on a.searchString_lowPriority = b.searchString_lowPriority
		option (maxdop 3)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': SearchString_LP set'

	drop table #stringList1
	drop table #stringList2

--	update lk_productSearchStrings_stage with (tablock)
--		set string_checksum = dbo.fn_checksum(searchString_nospaces)
--		option (maxdop 3)

--	create index ix_productSearchStrings_website_product_checksum on lk_productSearchStrings_stage (ukey_website, ukey_product, string_checksum) with fillfactor = 80

--print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': checksum set'

	--set nocount on
	--declare @nUkeyWebsite int
	--declare @nUkeyProduct int
	--declare @cSearch1 varchar(8000)
	--declare @cSearch2 varchar(8000)
	--set @nUkeyProduct = 0

	--while exists (select top 1 ukey_product from lk_productSearchStrings_stage where ukey_product > @nUkeyProduct)
	--begin
	--	select top 1
	--		@nUkeyProduct = ukey_product,
	--		@nUkeyWebsite = ukey_website,
	--		@cSearch1 = dbo.fn_returnLettersAndNumbers(searchString),
	--		@cSearch2 = dbo.fn_returnLettersAndNumbers(searchString_lowPriority)
	--		from lk_productSearchStrings_stage
	--		where ukey_product > @nUkeyProduct
	--		order by ukey_product

	--	update lk_productSearchStrings_stage with (tablock)
	--		set searchString = @cSearch1,
	--			searchString_lowPriority = @cSearch2,
	--			searchString_nospaces = left(replace(@cSearch1, ' ', '') + replace(@cSearch2, ' ', ''), 8000)
	--		where ukey_product = @nUkeyProduct
	--			and ukey_website = @nUkeyWebsite
	--end

	update lk_productSearchStrings_stage with (tablock)
		set lastModified = b.lastModified
		from lk_productSearchStrings_stage a
		join lk_productSearchStrings b (nolock) on a.ukey_product = b.ukey_product
			and b.ukey_website = a.ukey_website
			and a.searchString_nospaces = b.searchString_nospaces
--			and a.string_checksum = b.string_checksum
		option (maxdop 1)

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': LastModified set'


	--******************************************************************************************************
	-- indexing

	--CREATE NONCLUSTERED INDEX [ix_lkProductSearchStrings_product_website] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey_product] ASC,
	--	[ukey_website] ASC
	--) WITH fillfactor = 90

	CREATE UNIQUE NONCLUSTERED INDEX [ix_productSearchStrings_product] ON [dbo].[lk_productSearchStrings_stage]
	(
		[ukey_product] ASC
	) WITH fillfactor = 90

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_ukey_product] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey] ASC,
	--	[ukey_product] ASC
	--) WITH fillfactor = 90

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_ukey_website_includeProduct] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey] ASC,
	--	[ukey_website] ASC
	--) INCLUDE ( [ukey_product]) WITH fillfactor = 90

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_ukey_website_product] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey] ASC,
	--	[ukey_website] ASC,
	--	[ukey_product] ASC
	--) WITH fillfactor = 90

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_website_product_searchString] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey_website] ASC,
	--	[ukey_product] ASC,
	--	[ukey] ASC
	--)
	--INCLUDE ( [searchString]) WITH fillfactor = 90

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_website_product_searchString_lowPriority] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey_website] ASC,
	--	[ukey_product] ASC,
	--	[ukey] ASC
	--)
	--INCLUDE ( [searchString],
	--[searchString_lowPriority]) WITH fillfactor = 90

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_product_lastModified_website_searchString_searchStringLowPriority] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey_product] ASC,
	--	[lastModified] ASC
	--)
	--INCLUDE ( [ukey_website],
	--[searchString],
	--[searchString_lowPriority]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
	--GO

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_product_inc_website_searchString_searchStringLowPriority] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey_product] ASC
	--)
	--INCLUDE ( [ukey_website], [searchString], [searchString_lowPriority]) with fillfactor = 90


	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_website_product_ukey] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey_website] ASC,
	--	[ukey_product] ASC,
	--	[ukey] ASC
	--) WITH fillfactor = 90

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_website_ukey_includeProduct] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey_website] ASC,
	--	[ukey] ASC
	--)
	--INCLUDE ( [ukey_product]) WITH fillfactor = 90

	--CREATE NONCLUSTERED INDEX [ix_productSearchStrings_website_ukey_product] ON [dbo].[lk_productSearchStrings_stage]
	--(
	--	[ukey_website] ASC,
	--	[ukey] ASC,
	--	[ukey_product] ASC
	--) WITH fillfactor = 90

	CREATE NONCLUSTERED INDEX [ix_productSearchStrings_website_product_search1_search2_search3] ON [dbo].[lk_productSearchStrings_stage]
	(
		[ukey_website] ASC,
		[ukey_product] ASC
	) INCLUDE ( [searchString], [searchString_lowPriority], [searchString_nospaces]) with fillfactor = 90


print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': Created indexes'

	begin transaction swapSearchStrings

		exec sp_rename 'lk_productSearchStrings', 'lk_productSearchStrings_old'
		exec sp_rename 'lk_productSearchStrings_stage', 'lk_productSearchStrings'

		drop table lk_productSearchStrings_old

	commit transaction swapSearchStrings

print convert(varchar(20), dateDiff(ms, @dStartDate, getDate())) + ': Done'

end


--select * into lk_productSearchStrings_20120214 from lk_productSearchStrings
GO
