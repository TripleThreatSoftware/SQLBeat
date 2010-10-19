SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- exec pr_updateWebsiteProductCatalog 0, 3, 0
ALTER procedure [dbo].[pr_updateWebsiteProductCatalog] (@bPreview bit = 1, @nUkeyClient int, @nUkeyWebsite int = 0)
as
begin

--declare @bPreview bit
--declare @nUkeyClient int
--declare @nUkeyWebsite int
--set @bPreview = 0
--set @nUkeyClient = 1
--set @nUkeyWebsite = 0

	declare @nRowCount int
	declare @cMessage varchar(2000)
	declare @results table (ymd dateTime default getDate(), resultString varchar(2000))

	update AppDb.dbo.dm_fitment set ukey_model = 0 where ukey_model is null
	update AppDb.dbo.dm_fitment set ukey_modelYear = 0 where ukey_modelYear is null

	update AppDb.dbo.dm_fitment with (rowlock)
		set ukey_inventory = f.ukey
		from AppDb.dbo.dm_fitment a
		left outer join AppDb.dbo.dm_makes b on a.ukey_make = b.ukey
		left outer join AppDb.dbo.dm_models c on a.ukey_model = c.ukey
		left outer join AppDb.dbo.dm_drivelines d on a.ukey_driveline = d.ukey
		left outer join AppDb.dbo.dm_trimlevels e on a.ukey_trimLevel = e.ukey

		join AppDb.dbo.websites g on a.ukey_website = g.ukey
			and g.enabled = 1

		join AppDb_inventory.dbo.dm_fitment f on isnull(b.ukey_inventory, 0) = f.ukey_make
			and isnull(c.ukey_inventory, 0) = f.ukey_model
			and isnull(d.ukey_inventory, 0) = f.ukey_driveline
			and isnull(e.ukey_inventory, 0) = f.ukey_trimlevel
			and isnull(a.modelYear, 0) = f.modelYear
			and f.ukey_client = g.ukey_client
			and f.ukey_client = @nUkeyClient

		where isnull(a.ukey_inventory, 0) <> f.ukey

	update AppDb.dbo.dm_makes with (rowlock)
		set ukey_inventory = c.ukey
		from AppDb.dbo.dm_makes a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join AppDb_inventory.dbo.dm_makes c on b.ukey_client = c.ukey_client
			and a.makeName = c.makeName
		where isnull(a.ukey_inventory, 0) <> c.ukey

	update AppDb.dbo.dm_models with (rowlock)
		set ukey_inventory = c.ukey
		from AppDb.dbo.dm_models a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join AppDb_inventory.dbo.dm_models c on b.ukey_client = c.ukey_client
			and a.modelName = c.modelName
		join AppDb.dbo.dm_makes d on a.ukey_make = d.ukey
			and c.ukey_make = d.ukey_inventory
		where isnull(a.ukey_inventory, 0) <> c.ukey

	update AppDb.dbo.dm_drivelines with (rowlock)
		set ukey_inventory = c.ukey
		from AppDb.dbo.dm_drivelines a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join AppDb_inventory.dbo.dm_drivelines c on b.ukey_client = c.ukey_client
			and a.driveLine = c.driveLine
		join AppDb.dbo.dm_makes d on a.ukey_make = d.ukey
			and c.ukey_make = d.ukey_inventory
		where isnull(a.ukey_inventory, 0) <> c.ukey

	update AppDb.dbo.dm_trimLevels with (rowlock)
		set ukey_inventory = c.ukey
		from AppDb.dbo.dm_trimLevels a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join AppDb_inventory.dbo.dm_trimLevels c on b.ukey_client = c.ukey_client
			and a.trimLevel = c.trimLevel
		join AppDb.dbo.dm_makes d on a.ukey_make = d.ukey
			and c.ukey_make = d.ukey_inventory
		join AppDb.dbo.dm_models e on a.ukey_model = e.ukey
			and c.ukey_model = e.ukey_inventory
		where isnull(a.ukey_inventory, 0) <> c.ukey

	-- this is for categories without parents
	update a with (rowlock)
		set ukey_inventory = c.ukey,
			enabled = 1
		from AppDb.dbo.dm_categories a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join AppDb_inventory.dbo.dm_categories c on b.ukey_client = c.ukey_client
			and a.categoryname = c.categoryName
			and isnull(c.ukey_parent, 0) = 0

		join AppDb_inventory.dbo.websiteCategories f on c.ukey = f.ukey_category
			and a.ukey_website = f.ukey_website
			and f.ukey_client = @nUkeyClient
		where isnull(a.ukey_inventory, 0) <> c.ukey
			and isnull(a.ukey_parent, 0) = 0

	-- this is for categories with parents
	update a with (rowlock)
		set ukey_inventory = c.ukey,
			enabled = 1
		from AppDb.dbo.dm_categories a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join AppDb_inventory.dbo.dm_categories c on b.ukey_client = c.ukey_client
			and a.categoryname = c.categoryName
			and isnull(c.ukey_parent, 0) <> 0

		join AppDb.dbo.dm_categories d on a.ukey_parent = d.ukey
			and a.ukey_website = d.ukey_website
		join AppDb_inventory.dbo.dm_categories e on c.ukey_parent = e.ukey
			and b.ukey_client = e.ukey_client
			and d.categoryName = e.categoryName

		join AppDb_inventory.dbo.websiteCategories f on c.ukey = f.ukey_category
			and a.ukey_website = f.ukey_website
			and f.ukey_client = @nUkeyClient
		where isnull(a.ukey_inventory, 0) <> c.ukey
			and isnull(a.ukey_parent, 0) <> 0

	update AppDb.dbo.products with (rowlock)
		set ukey_inventory = c.ukey
		from AppDb.dbo.products a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		left outer join AppDb_inventory.dbo.products c on b.ukey_client = c.ukey_client
			and a.stockCode = c.stockCode
		where isnull(a.ukey_inventory, 0) <> isnull(c.ukey, 0)

	update AppDb.dbo.dm_modelRanges with (rowlock)
		set ukey_inventory = c.ukey
		from AppDb.dbo.dm_modelRanges a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join AppDb_inventory.dbo.dm_modelRanges c on b.ukey_client = c.ukey_client
			and a.modelRange = c.modelRange
		where isnull(a.ukey_inventory, 0) <> c.ukey

	update AppDb.dbo.dm_options with (rowlock)
		set ukey_inventory = c.ukey
		from AppDb.dbo.dm_options a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join AppDb_inventory.dbo.dm_options c on b.ukey_client = c.ukey_client
			and a.optionName = c.optionName
		where isnull(a.ukey_inventory, 0) <> c.ukey

	update AppDb.dbo.assemblies
		set ukey_inventory = c.ukey
		from AppDb.dbo.assemblies a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		join assemblies c on b.ukey_client = c.ukey_client
			and a.externalID = c.externalID
		where isnull(a.ukey_inventory, 0) <> c.ukey

	insert into @results (resultString) values ('Inventory keys set')


	if @bPreview = 1
		begin transaction updateProducts

	select stockCode, ukey_website,
		max(productDescription) as productDescription,
		max(specialNote) as specialNote,
		max(applicationNotes) as applicationNotes,
		max(price) as price,
		max(listPrice) as listPrice,
		max(additionalCoreChargeAmount) as additionalCoreChargeAmount,
		max(quantityRequired) as quantityRequired
		into #products
		from AppDb_inventory.dbo.products a
		join AppDb_inventory.dbo.websiteProducts b on a.ukey = b.ukey_product
			and b.ukey_client = @nUkeyClient
		where a.enabled = 1
			and a.ukey_client = @nUkeyClient
			and (b.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and b.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
		group by stockCode, ukey_website

	create unique index ix_tmp_product_website_stockCode on #products (ukey_website, stockCode) with fillfactor = 80
	create index ix_tmp_products_website_stockCode_price on #products (ukey_website, stockCode, price) with fillfactor = 80

	update AppDb.dbo.products with (rowlock)
		set enabled = 0
--select a.*, b.*
		from AppDb.dbo.products a
		left outer join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
		where b.ukey_website is null
			and a.enabled = 1
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' products disabled'
	insert into @results (resultString) values (@cMessage)

	update AppDb.dbo.products with (rowlock)
		set enabled = 1
--select a.*, b.*
		from AppDb.dbo.products a
		join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
		where a.enabled = 0
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' products enabled'
	insert into @results (resultString) values (@cMessage)

	update AppDb.dbo.products with (rowlock)
		set productDescription = b.productDescription
--select a.stockCode, a.productdescription, b.productdescription
		from AppDb.dbo.products a
		join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
			and isnull(a.productDescription, '') <> isnull(b.productDescription, '')
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' product descriptions updated'
	insert into @results (resultString) values (@cMessage)

	update AppDb.dbo.products with (rowlock)
		set specialNote = b.specialNote
	--select a.*, b.*
		from AppDb.dbo.products a
		join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
			and isnull(a.specialNote, '') <> isnull(b.specialNote, '')
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' product special notes updated'
	insert into @results (resultString) values (@cMessage)

	update AppDb.dbo.products with (rowlock)
		set productApplication = b.applicationNotes
	--select a.*, b.*
		from AppDb.dbo.products a
		join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
			and isnull(a.productApplication, '') <> isnull(b.applicationNotes, '')
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' product application notes updated'
	insert into @results (resultString) values (@cMessage)


	update AppDb.dbo.products with (rowlock)
		set price = b.price
--select a.*, b.*
		from AppDb.dbo.products a
		join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
			and isnull(a.price, 0) <> isnull(b.price, 0)
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' product prices updated'
	insert into @results (resultString) values (@cMessage)

	update AppDb.dbo.products with (rowlock)
		set corePrice = b.additionalCoreChargeAmount
	--select a.*, b.*
		from AppDb.dbo.products a
		join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
			and isnull(a.corePrice, 0) <> isnull(b.additionalCoreChargeAmount, 0)
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' product core charges updated'
	insert into @results (resultString) values (@cMessage)

	update AppDb.dbo.products with (rowlock)
		set listprice = b.listprice
	--select a.*, b.*
		from AppDb.dbo.products a
		join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
			and isnull(a.listprice, 0) <> isnull(b.listprice, 0)
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' product list prices updated'
	insert into @results (resultString) values (@cMessage)

	update AppDb.dbo.products with (rowlock)
		set quantityRequired = b.quantityRequired
	--select a.*, b.*
		from AppDb.dbo.products a
		join #products b on a.stockCode = b.stockCode
			and a.ukey_website = b.ukey_website
			and isnull(a.quantityRequired, 0) <> isnull(b.quantityRequired, 0)
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' product required quantities updated'
	insert into @results (resultString) values (@cMessage)

	drop table #products

	insert into AppDb.dbo.products (stockCode, productDescription, price, enabled, isOnSale, listPrice, ukey_website, altcode1, quantityRequired, specialNote, productApplication, shippingCost, coreChargeAmount, ukey_inventory, isAccessory)
	select a.stockCode, a.productDescription, a.price, a.enabled, a.isOnSale, a.listPrice, b.ukey_website, a.altcode1, a.quantityRequired, a.specialNote, a.applicationNotes, a.shippingCost, a.additionalCoreChargeAmount, a.ukey, a.isAccessory
		from products a
		join websiteProducts b on a.ukey = b.ukey_product
			and a.ukey_client = b.ukey_client
		left outer join AppDb.dbo.products c on a.ukey = c.ukey_inventory
			and b.ukey_website = c.ukey_website
		where c.ukey is null
			and a.ukey_client = @nUkeyClient

	set @nRowCount = @@rowcount
	set @cMessage = convert(varchar(20), @nRowCount) + ' new products added'
	insert into @results (resultString) values (@cMessage)

	--**********************************************************************************************************************
	-- Categories

-- --	drop table #categories

	select distinct e.ukey_website, a.categoryName, f.categoryName as parentCategoryName,
		convert(int, 0) as ukey_category,
		convert(int, 0) as ukey_parent,
		a.ukey as ukey_inventory
		into #categories
		from AppDb_inventory.dbo.dm_categories a
		join AppDb_inventory.dbo.websiteCategories e on a.ukey = e.ukey_category
			and e.ukey_client = @nUkeyClient

		left outer join AppDb_inventory.dbo.dm_categories f on a.ukey_parent = f.ukey
			and f.ukey_client = @nUkeyClient
		left outer join AppDb_inventory.dbo.websiteCategories g on f.ukey = g.ukey_category
			and g.ukey_client = @nUkeyClient
			and e.ukey_website = g.ukey_website
		where a.ukey_client = @nUkeyClient
			and (e.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and e.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

			and (
				a.ukey_parent is null
				or (a.ukey_parent is not null and g.ukey is not null)
				)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' categories identified')

	update #categories set ukey_category = null, ukey_parent = null

	update #categories
		set ukey_category = b.ukey
		from #categories a
		join AppDb.dbo.dm_categories b on a.categoryName = b.categoryName
			and b.ukey_website = a.ukey_website
		left outer join AppDb.dbo.dm_categories c on a.parentCategoryName = c.categoryName
			and c.ukey_website = a.ukey_website
			and b.ukey_parent = c.ukey
		where a.parentCategoryName is null
			or (a.parentCategoryName is not null  and c.ukey is not null)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' existing parent categories found')

	update #categories
		set ukey_parent = b.ukey
		from #categories a
		join AppDb.dbo.dm_categories b on a.parentCategoryName = b.categoryName
			and b.ukey_website = a.ukey_website
			and isnull(b.ukey_parent, 0) = 0
		where a.parentCategoryName is not null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' existing categories found')

	delete AppDb.dbo.dm_categories with (rowlock)
		from AppDb.dbo.dm_categories a
		left outer join (
			select distinct ukey_website, ukey_category
				from (
					select distinct ukey_website, ukey_category from #categories
					union
					select distinct ukey_website, ukey_parent from #categories
					) a
				where isnull(ukey_category, 0) <> 0
			) b on a.ukey = b.ukey_category
				and a.ukey_website = b.ukey_website
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and b.ukey_category is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' categories deleted')

	insert into AppDb.dbo.dm_categories (categoryName, ukey_website, enabled, ukey_parent, ukey_inventory)
	select distinct a.categoryName, a.ukey_website, 1, a.ukey_parent, ukey_inventory
		from #categories a
		where ukey_category is null
			and (
				parentCategoryName is null
				or (parentCategoryName is not null and ukey_parent is not null)
				)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' categories added')

	update #categories
		set ukey_category = b.ukey
		from #categories a
		join AppDb.dbo.dm_categories b on a.categoryName = b.categoryName
			and b.ukey_website = a.ukey_website
		left outer join AppDb.dbo.dm_categories c on a.parentCategoryName = c.categoryName
			and c.ukey_website = a.ukey_website
			and b.ukey_parent = c.ukey
		where a.ukey_category is null
			and (
				a.parentCategoryName is null
				or (a.parentCategoryName is not null and c.ukey is not null)
				)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' existing parent categories found')

	update #categories
		set ukey_parent = b.ukey
		from #categories a
		join AppDb.dbo.dm_categories b on a.parentCategoryName = b.categoryName
			and b.ukey_website = a.ukey_website
			and isnull(b.ukey_parent, 0) = 0
		where a.parentCategoryName is not null
			and a.ukey_parent is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' existing categories found')

	insert into AppDb.dbo.dm_categories (categoryName, ukey_website, enabled, ukey_parent, ukey_inventory)
	select distinct a.categoryName, a.ukey_website, 1, a.ukey_parent, ukey_inventory
		from #categories a
		where ukey_category is null


	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' additional categories added')

	drop table #categories


	--**********************************************************************************************************************
	-- Product Categories

--	-- drop table #productCategories

	select distinct b.ukey_website, f.ukey as ukey_category, g.ukey as ukey_product
		into #productCategories
		from AppDb_inventory.dbo.products a
		join AppDb_inventory.dbo.websiteProducts b on a.ukey = b.ukey_product
			and b.ukey_client = @nUkeyClient
		join AppDb_inventory.dbo.productCategories c on a.ukey = c.ukey_product
			and c.ukey_client = @nUkeyClient
		join AppDb_inventory.dbo.dm_categories d on c.ukey_category = d.ukey
			and d.ukey_client = @nUkeyClient
		join AppDb_inventory.dbo.websiteCategories e on d.ukey = e.ukey_category
			and e.ukey_client = @nUkeyClient
			and b.ukey_website = e.ukey_website

		join AppDb.dbo.dm_categories f (nolock) on d.ukey = f.ukey_inventory
			and f.ukey_website = e.ukey_website
		join AppDb.dbo.products g (nolock) on a.ukey = g.ukey_inventory
			and g.ukey_website = b.ukey_website
		where a.enabled = 1
			and a.ukey_client = @nUkeyClient
			and (b.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and b.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' product categories identified')

	create index ix_tmp_productcategories_website_product_categoryname on #productCategories (ukey_website, ukey_product, ukey_category) with fillfactor = 80

	insert into AppDb.dbo.productCategories (ukey_website, ukey_category, ukey_product)
	select distinct a.ukey_website, a.ukey_category, a.ukey_product
		from #productCategories a
		left outer join AppDb.dbo.productCategories d (nolock) on a.ukey_category = d.ukey_category
			and a.ukey_product = d.ukey_product
			and d.ukey_website = a.ukey_website
		where d.ukey is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' categories associations added')

	delete AppDb.dbo.productCategories
--select *
		from AppDb.dbo.productCategories a
		left outer join #productCategories b on a.ukey_website = b.ukey_website
			and a.ukey_product = b.ukey_product
			and a.ukey_category = b.ukey_category
		where b.ukey_product is null
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' category associations deleted')

	drop table #productCategories

	--*****************************************************************************************************************
	--*****************************************************************************************************************
	-- fitment

	--*****************************************************************************************************************
	-- first, we delete

	delete AppDb.dbo.dm_makes
--select a.*
		from AppDb.dbo.dm_makes a
		left outer join dm_makes b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where b.ukey is null
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' make names dropped')

--select a.*
	delete AppDb.dbo.dm_models
		from AppDb.dbo.dm_models a
		left outer join dm_models b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where b.ukey is null
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model names dropped')

--select a.*
	delete AppDb.dbo.dm_driveLines
		from AppDb.dbo.dm_driveLines a
		left outer join dm_driveLines b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where b.ukey is null
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' driveline names dropped')

--select a.*
	delete AppDb.dbo.dm_trimLevels
		from AppDb.dbo.dm_trimLevels a
		left outer join dm_trimLevels b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where b.ukey is null
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' trim level names dropped')

	update AppDb.dbo.dm_makes
		set makeName = b.makeName,
			showOnHomePage = 1
		from AppDb.dbo.dm_makes a
		join dm_makes b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and isnull(a.makeName, '') <> isnull(b.makeName, '')

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' make names updated')

	update AppDb.dbo.dm_models
		set modelName = b.modelName
		from AppDb.dbo.dm_models a
		join dm_models b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and isnull(a.modelName, '') <> isnull(b.modelName, '')

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model names updated')

	update AppDb.dbo.dm_driveLines
		set driveLine = b.driveLine
		from AppDb.dbo.dm_driveLines a
		join dm_driveLines b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and isnull(a.driveLine, '') <> isnull(b.driveLine, '')

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' driveLine names updated')

	update AppDb.dbo.dm_trimLevels
		set trimLevel = b.trimLevel
		from AppDb.dbo.dm_trimLevels a
		join dm_trimLevels b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and isnull(a.trimLevel, '') <> isnull(b.trimLevel, '')

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' trim level names updated')

	update AppDb.dbo.dm_modelRanges
		set modelRange = b.modelRange
		from AppDb.dbo.dm_modelRanges a
		join dm_modelRanges b on a.ukey_inventory = b.ukey
			and b.ukey_client = @nUkeyClient
		where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and isnull(a.modelRange, '') <> isnull(b.modelRange, '')

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model range names updated')

	--*****************************************************************************************************************
	-- add new stuff

	insert into AppDb.dbo.dm_makes (makeName, showOnHomePage, ukey_website, ukey_inventory)
	select a.makeName, 1, b.ukey_website, a.ukey
		from dm_makes a
		join websiteMakes b on a.ukey = b.ukey_make
			and b.ukey_client = @nUkeyClient
		left outer join AppDb.dbo.dm_makes	c on a.ukey = c.ukey_inventory
			and b.ukey_website = c.ukey_website
		where (b.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and b.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and c.ukey is null
			and a.ukey_client = @nUkeyClient

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' makes added')

	insert into AppDb.dbo.dm_models (modelName, enabled, ukey_website, ukey_inventory, ukey_make)
	select a.modelName, 1, b.ukey_website, a.ukey, d.ukey
		from dm_models a
		join websiteModels b on a.ukey = b.ukey_model
			and b.ukey_client = @nUkeyClient
		left outer join AppDb.dbo.dm_models c on a.ukey = c.ukey_inventory
			and b.ukey_website = c.ukey_website
		join AppDb.dbo.dm_makes d on d.ukey_inventory = a.ukey_make
			and d.ukey_website = b.ukey_website
		where (b.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and b.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and c.ukey is null
			and a.ukey_client = @nUkeyClient

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' models added')

	insert into AppDb.dbo.dm_modelYears (modelYear, ukey_model, ukey_website)
	select distinct c.modelYear, d.ukey, b.ukey_website
		from dm_models a
		join websiteModels b on a.ukey = b.ukey_model
			and b.ukey_client = @nUkeyClient
		join dm_fitment c on a.ukey = c.ukey_model
			and c.ukey_client = @nUkeyClient
		join AppDb.dbo.dm_models d on a.ukey = d.ukey_inventory
			and b.ukey_website = d.ukey_website

		left outer join AppDb.dbo.dm_modelYears e on e.modelYear = c.modelYear
			and e.ukey_model = d.ukey
			and b.ukey_website = e.ukey_website
		where (b.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and b.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and e.ukey is null
			and a.ukey_client = @nUkeyClient
			and isnull(c.modelYear, 0) <> 0

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model years added')

	insert into AppDb.dbo.dm_drivelines (driveLine, ukey_make, ukey_website, ukey_inventory)
	select distinct a.driveline, d.ukey, c.ukey_website, a.ukey
		from dm_drivelines a
		join dm_makes b on a.ukey_make = b.ukey
			and a.ukey_client = b.ukey_client
		join websiteMakes c on b.ukey = c.ukey_make
			and a.ukey_client = c.ukey_client
		join AppDb.dbo.dm_makes d on b.ukey = d.ukey_inventory

		left outer join AppDb.dbo.dm_drivelines e on a.ukey = e.ukey_inventory
			and c.ukey_website = e.ukey_website
		where (c.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and c.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and e.ukey is null
			and a.ukey_client = @nUkeyClient
			and isnull(a.driveline, '') <> ''

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' drivelines added')

	insert into AppDb.dbo.dm_trimLevels (trimLevel, ukey_make, ukey_model, ukey_website, ukey_inventory)
	select distinct a.trimLevel, f.ukey, g.ukey, c.ukey_website, a.ukey
		from dm_trimLevels a
		join dm_makes b on a.ukey_make = b.ukey
			and a.ukey_client = b.ukey_client
		join websiteMakes c on b.ukey = c.ukey_make
			and a.ukey_client = c.ukey_client
		join dm_models d on a.ukey_model = d.ukey
			and a.ukey_client = d.ukey_client
		join websiteModels e on d.ukey = e.ukey_model
			and a.ukey_client = e.ukey_client
			and c.ukey_website = e.ukey_website

		join AppDb.dbo.dm_makes f on b.ukey = f.ukey_inventory
		join AppDb.dbo.dm_models g on d.ukey = g.ukey_inventory

		left outer join AppDb.dbo.dm_trimLevels h on a.ukey = h.ukey_inventory
			and c.ukey_website = h.ukey_website
		where (c.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and c.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and h.ukey is null
			and a.ukey_client = @nUkeyClient
			and isnull(a.trimLevel, '') <> ''

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' trim levels added')

	insert into AppDb.dbo.dm_modelRanges (modelRange, ukey_website, ukey_inventory)
	select a.modelRange, b.ukey_website, a.ukey
		from dm_modelRanges a
		join (
			select distinct ukey_modelRange, ukey_make
				from dm_modelRangeFitments a
				join dm_fitment b on a.ukey_fitment = b.ukey
					and b.ukey_client = @nUkeyClient
				where a.ukey_client = @nUkeyClient
			) d on a.ukey = d.ukey_modelRange
		join websiteMakes b on b.ukey_make = d.ukey_make
			and b.ukey_client = @nUkeyClient
		left outer join AppDb.dbo.dm_modelRanges c on a.ukey = c.ukey_inventory
			and b.ukey_website = c.ukey_website
		where (b.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and b.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and c.ukey is null
			and a.ukey_client = @nUkeyClient

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model ranges added')

	--*****************************************************************************************************************
	-- now, we delete stuff

	delete AppDb.dbo.dm_makes
--	select a.*
		from AppDb.dbo.dm_makes a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		left outer join (select distinct a.ukey, b.ukey_website from dm_makes a join websiteMakes b on a.ukey = b.ukey_make where a.ukey_client = @nUkeyClient) c on a.ukey_inventory = c.ukey
			and a.ukey_website = c.ukey_website
		where (c.ukey is null or a.ukey_inventory is null)
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' makes deleted from website')

	delete AppDb.dbo.dm_models
--	select a.*
		from AppDb.dbo.dm_models a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		left outer join (select distinct a.ukey, b.ukey_website from dm_models a join websiteModels b on a.ukey = b.ukey_model where a.ukey_client = @nUkeyClient) c on a.ukey_inventory = c.ukey
			and a.ukey_website = c.ukey_website
		where (c.ukey is null or a.ukey_inventory is null)
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' models deleted from website')

	delete AppDb.dbo.dm_drivelines
--	select a.*
		from AppDb.dbo.dm_drivelines a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		left outer join (
			select distinct c.ukey, b.ukey_website
				from dm_makes a
				join websiteMakes b on a.ukey = b.ukey_make
				join dm_drivelines c on a.ukey = c.ukey_make
				where a.ukey_client = @nUkeyClient
			) c on a.ukey_inventory = c.ukey
			and a.ukey_website = c.ukey_website
		where (c.ukey is null or a.ukey_inventory is null)
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' drivelines deleted from website')

	delete AppDb.dbo.dm_trimLevels
--	select a.*
		from AppDb.dbo.dm_trimLevels a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		left outer join (
			select distinct a.ukey, e.ukey_website
				from dm_trimLevels a
				join dm_makes b on a.ukey_make = b.ukey
					and a.ukey_client = b.ukey_client
				join websiteMakes c on b.ukey = c.ukey_make
					and a.ukey_client = c.ukey_client
				join dm_models d on a.ukey_model = d.ukey
					and a.ukey_client = d.ukey_client
				join websiteModels e on d.ukey = e.ukey_model
					and a.ukey_client = e.ukey_client
					and c.ukey_website = e.ukey_website
				where a.ukey_client = @nUkeyClient
			) c on a.ukey_inventory = c.ukey
			and a.ukey_website = c.ukey_website
		where (c.ukey is null or a.ukey_inventory is null)
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' trim levels deleted from website')

	delete AppDb.dbo.dm_modelYears
--	select a.*
		from AppDb.dbo.dm_modelYears a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		left outer join (
			select distinct a.modelYear, b.ukey as ukey_model, e.ukey_website
				from dm_fitment a
				join websiteModels e on a.ukey_model = e.ukey_model
					and a.ukey_client = e.ukey_client
				join AppDb.dbo.dm_models b on e.ukey_website = b.ukey_website
					and a.ukey_model = b.ukey_inventory
				where a.ukey_client = @nUkeyClient
					and a.modelYear <> 0
			) c on a.modelYear = c.modelYear
				and a.ukey_model = c.ukey_model
				and a.ukey_website = c.ukey_website
		where c.ukey_website is null
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model years deleted from website')

	delete AppDb.dbo.dm_modelRanges
--	select a.*
		from AppDb.dbo.dm_modelRanges a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
		left outer join (
			select distinct c.ukey_modelRange, b.ukey_website
				from dm_makes a
				join websiteMakes b on a.ukey = b.ukey_make
				join (
					select distinct ukey_modelRange, ukey_make
						from dm_modelRangeFitments a
						join dm_fitment b on a.ukey_fitment = b.ukey
							and b.ukey_client = @nUkeyClient
						where a.ukey_client = @nUkeyClient
					) c on a.ukey = c.ukey_make
				where a.ukey_client = @nUkeyClient
			) c on a.ukey_inventory = c.ukey_modelRange
			and a.ukey_website = c.ukey_website
		where (c.ukey_modelRange is null or a.ukey_inventory is null)
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model ranges deleted from website')

	--***********************************************************************
	-- now, we deal with dm_fitment

	insert into AppDb.dbo.dm_fitment (ukey_website, ukey_make, ukey_model, ukey_modelYear, modelYear, ukey_driveline, ukey_trimLevel, ukey_inventory)
	select distinct
		k.ukey_website,
		isnull(f.ukey, 0) as ukey_make,
		isnull(g.ukey, 0) as ukey_model,
		isnull(j.ukey, 0) as ukey_modelYear,
		isnull(a.modelYear, 0) as modelYear,
		isnull(h.ukey, 0) as ukey_driveline,
		isnull(i.ukey, 0) as ukey_trimLevel,
		a.ukey
		from dm_fitment a
		left outer join dm_makes b on a.ukey_make = b.ukey
		left outer join dm_models c on a.ukey_model = c.ukey
		left outer join dm_drivelines d on a.ukey_driveline = d.ukey
		left outer join dm_trimlevels e on a.ukey_trimlevel = e.ukey

		left outer join AppDb.dbo.dm_makes f on b.ukey = f.ukey_inventory
		left outer join AppDb.dbo.dm_models g on c.ukey = g.ukey_inventory
		left outer join AppDb.dbo.dm_drivelines h on d.ukey = h.ukey_inventory
		left outer join AppDb.dbo.dm_trimlevels i on e.ukey = i.ukey_inventory
		left outer join AppDb.dbo.dm_modelYears j on g.ukey = j.ukey_model
			and convert(varchar(100), a.modelYear) = j.modelYear

		join websiteMakes k on a.ukey_make = k.ukey_make
		join websiteModels l on (a.ukey_model = l.ukey_model or a.ukey_model = 0)
			and k.ukey_website = l.ukey_website

		left outer join AppDb.dbo.dm_fitment m on m.ukey_inventory = a.ukey

		where m.ukey is null
			and (k.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and k.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			and a.ukey_client = @nUkeyClient

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' fitments added')

	--update AppDb.dbo.dm_fitment
	--	set ukey_inventory = null

	--update AppDb.dbo.dm_fitment
	--	set ukey_inventory = f.ukey
	--	from AppDb.dbo.dm_fitment a
	--	left outer join AppDb.dbo.dm_makes b on a.ukey_make = b.ukey
	--	left outer join AppDb.dbo.dm_models c on a.ukey_model = c.ukey
	--	left outer join AppDb.dbo.dm_drivelines d on a.ukey_driveline = d.ukey
	--	left outer join AppDb.dbo.dm_trimlevels e on a.ukey_trimLevel = e.ukey

	--	join dm_fitment f on isnull(b.ukey_inventory, 0) = f.ukey_make
	--		and isnull(c.ukey_inventory, 0) = f.ukey_model
	--		and isnull(d.ukey_inventory, 0) = f.ukey_driveline
	--		and isnull(e.ukey_inventory, 0) = f.ukey_trimlevel
	--		and isnull(a.modelYear, 0) = f.modelYear

	--insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' website fitments associated with inventory fitments')



	delete AppDb.dbo.dm_fitment
--select a.*
		from AppDb.dbo.dm_fitment a
		left outer join (
			select distinct a.ukey, b.ukey_website
				from dm_fitment a
				join websiteMakes b on a.ukey_make = b.ukey_make
				join websiteModels c on ((a.ukey_model = c.ukey_model and b.ukey_website = c.ukey_website) or a.ukey_model = 0)
				where a.ukey_client = @nUkeyClient
			) b on a.ukey_inventory = b.ukey
				and a.ukey_website = b.ukey_website
		where b.ukey is null
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' fitments removed')

	--******************************************************************************************
	-- Model Range Fitment

	delete AppDb.dbo.dm_modelRangeFitments
		from AppDb.dbo.dm_modelRangeFitments a
		join AppDb.dbo.dm_modelRanges b on a.ukey_modelRange = b.ukey
		join AppDb.dbo.dm_fitment c on a.ukey_fitment = c.ukey
		left outer join (
			select distinct a.ukey_modelRange, a.ukey_fitment, c.ukey_website
				from dm_modelRangeFitments a
				join dm_fitment b on a.ukey_fitment = b.ukey
					and b.ukey_client = @nUkeyClient
				join websiteMakes c on b.ukey_make = c.ukey_make
					and c.ukey_client = @nUkeyClient
					and (c.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
					and c.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
				where a.ukey_client = @nUkeyClient
			) d on b.ukey_inventory = d.ukey_modelRange
			and a.ukey_website = d.ukey_website
			and c.ukey_inventory = d.ukey_fitment

		where d.ukey_fitment is null
			and d.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model range fitments removed')


	insert into AppDb.dbo.dm_modelRangeFitments (ukey_website, ukey_modelRange, ukey_fitment)
	select a.ukey_website, c.ukey, d.ukey
		from (
			select distinct a.ukey_modelRange, a.ukey_fitment, c.ukey_website
				from dm_modelRangeFitments a
				join dm_fitment b on a.ukey_fitment = b.ukey
					and b.ukey_client = @nUkeyClient
				join websiteMakes c on b.ukey_make = c.ukey_make
					and c.ukey_client = @nUkeyClient
					and (c.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
					and c.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
				where a.ukey_client = @nUkeyClient
			) a
		left outer join (
			select a.ukey_website, a.ukey_inventory as ukey_modelRange, c.ukey_inventory as ukey_fitment
				from AppDb.dbo.dm_modelRanges a
				join AppDb.dbo.dm_modelRangeFitments b on a.ukey = b.ukey_modelRange
					and a.ukey_website = b.ukey_website
				join AppDb.dbo.dm_fitment c on b.ukey_fitment = c.ukey
					and a.ukey_website = c.ukey_website
				where (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
					and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)
			) b on a.ukey_modelRange = b.ukey_modelRange
			and a.ukey_fitment = b.ukey_fitment
			and a.ukey_website = b.ukey_website

		join AppDb.dbo.dm_modelRanges c on a.ukey_modelRange = c.ukey_inventory
			and c.ukey_website = a.ukey_website
		join AppDb.dbo.dm_fitment d on a.ukey_fitment = d.ukey_inventory
			and d.ukey_website = a.ukey_website
		where b.ukey_fitment is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' model range fitments added')

	--******************************************************************************************


	delete AppDb.dbo.assemblies
--select a.*
		from AppDb.dbo.assemblies a
		left outer join websiteAssemblies b on a.ukey_inventory = b.ukey_assembly
			and a.ukey_website = b.ukey_website
			and b.ukey_client = @nUkeyClient
		join AppDb.dbo.websites c on a.ukey_website = c.ukey
			and c.ukey_client = @nUkeyClient
		where b.ukey is null
			and c.ukey_client = @nUkeyClient

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assemblies deleted')


	insert into AppDb.dbo.assemblies (ukey_website, assemblyName, assemblyDescription, externalID, ukey_inventory)
	select b.ukey_website, a.assemblyName, a.assemblyDescription, a.externalID, a.ukey
		from assemblies a
		join websiteAssemblies b on a.ukey = b.ukey_assembly
		left outer join AppDb.dbo.assemblies c on b.ukey_website = c.ukey_website
			and a.ukey = c.ukey_inventory
		where c.ukey is null
			and a.ukey_client = @nUkeyClient
			and (b.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and b.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assemblies added')

	update AppDb.dbo.assemblies
		set imageURL = null, thumbnailURl = null, assemblyName = b.assemblyName, assemblyDescription = b.assemblyDescription
		from AppDb.dbo.assemblies a
		join assemblies b on a.ukey_inventory = b.ukey
		where b.ukey_client = @nUkeyClient
			and (
				--isnull(a.imageURL, '') <> isnull(b.imageURL, '')
				--or isnull(a.thumbnailURL, '') <> isnull(b.thumbnailURL, '')
				isnull(a.assemblyName, '') <> isnull(b.assemblyName, '')
				or isnull(a.assemblyDescription, '') <> isnull(b.assemblyDescription, '')
				)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assemblies updated')

	insert into AppDb.dbo.assemblyImages (ukey_website, ukey_assembly, imageURL, thumbnailURL, imageDescription, imageTitle)
	select e.ukey_website, b.ukey as ukey_assembly, c.imageURL, c.thumbnailURL, c.imageDescription, c.imageTitle
		from assemblies a
		join AppDb.dbo.assemblies b on a.ukey = b.ukey_inventory
		join assemblyImages c on a.ukey = c.ukey_assembly
		left outer join AppDb.dbo.assemblyImages d on b.ukey = d.ukey_assembly
			and b.ukey_website = d.ukey_website
			and isnull(c.imageURL, '') = isnull(d.imageURL, '')
		join websiteAssemblies e on a.ukey = e.ukey_assembly
			and b.ukey_website = e.ukey_website
		where d.ukey is null
			and a.ukey_client = @nUkeyClient
			and (e.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and e.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assembly images added')

-- drop table #assemblyProducts
	select distinct f.ukey as ukey_product, f.ukey_website, g.ukey as ukey_assembly, c.assemblyIndex, c.applicationNotes
		into #assemblyProducts
		from assemblies a
		join websiteAssemblies b on a.ukey = b.ukey_assembly
		join assemblyProducts c on a.ukey = c.ukey_assembly
		join products d on c.ukey_product = d.ukey
		join websiteProducts e on d.ukey = e.ukey_product
			and b.ukey_website = e.ukey_website
		join AppDb.dbo.products f on d.stockCode = f.stockCode
			and e.ukey_website = f.ukey_website
		join AppDb.dbo.assemblies g on a.ukey = g.ukey_inventory
			and g.ukey_website = b.ukey_Website
		where a.ukey_client = @nUkeyClient

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assembly products identified')



	insert into AppDb.dbo.assemblyProducts (ukey_website, ukey_product, ukey_assembly, assemblyIndex, applicationNotes)
	select a.ukey_website, a.ukey_product, a.ukey_assembly, a.assemblyIndex, a.applicationNotes
		from #assemblyProducts a
		left outer join AppDb.dbo.assemblyProducts b on a.ukey_assembly = b.ukey_assembly
			and a.ukey_product = b.ukey_product
			and a.ukey_website = b.ukey_website
		where b.ukey is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assembly products added')

	delete AppDb.dbo.assemblyProducts
		from AppDb.dbo.assemblyProducts a
		left outer join #assemblyProducts b on a.ukey_assembly = b.ukey_assembly
			and a.ukey_product = b.ukey_product
			and a.ukey_website = b.ukey_website
		where b.ukey_product is null
			and a.ukey_website in (select ukey from AppDb.dbo.websites where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assembly products removed')

	update AppDb.dbo.assemblyProducts
		set assemblyIndex = b.assemblyIndex,
			applicationNotes = b.applicationNotes
		from AppDb.dbo.assemblyProducts a
		join #assemblyProducts b on a.ukey_assembly = b.ukey_assembly
			and a.ukey_product = b.ukey_product
			and a.ukey_website = b.ukey_website
			and (isnull(a.assemblyIndex, '') = isnull(b.assemblyIndex, '') or isnull(a.assemblyIndex, '') = '')
		where a.ukey_website in (select ukey from AppDb.dbo.websites where ukey_client = @nUkeyClient)
			and (
				isnull(a.assemblyIndex, '') <> isnull(b.assemblyIndex, '')
				or isnull(a.applicationNotes, '') <> isnull(b.applicationNotes, '')
				)
			and not (isnull(a.applicationNotes, '') <> '' and isnull(b.applicationNotes, '') = '')
			and not (isnull(a.assemblyIndex, '') <> '' and isnull(b.assemblyIndex, '') = '')

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assembly products updated')

	insert into AppDb.dbo.assemblyFitment (ukey_website, ukey_assembly, ukey_fitment)
	select distinct b.ukey_website, c.ukey, d.ukey
		from assemblyFitment a
		join websiteAssemblies b on a.ukey_assembly = b.ukey_assembly
			and b.ukey_client = a.ukey_client
		join AppDb.dbo.assemblies c on a.ukey_assembly = c.ukey_inventory
			and b.ukey_website = c.ukey_website
		join AppDb.dbo.dm_fitment d on a.ukey_fitment = d.ukey_inventory
			and b.ukey_website = d.ukey_website

		left outer join AppDb.dbo.assemblyFitment e on b.ukey_website = e.ukey_website
			and c.ukey = e.ukey_assembly
			and d.ukey = e.ukey_fitment

		where e.ukey is null
			and (b.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and b.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assembly fitments added')

	delete AppDb.dbo.assemblyFitment
		from AppDb.dbo.assemblyFitment a
		left outer join (
			select distinct b.ukey_website, c.ukey as ukey_assembly, d.ukey as ukey_fitment
				from assemblyFitment a
				join websiteAssemblies b on a.ukey_assembly = b.ukey_assembly
					and b.ukey_client = a.ukey_client
				join AppDb.dbo.assemblies c on a.ukey_assembly = c.ukey_inventory
					and b.ukey_website = c.ukey_website
				join AppDb.dbo.dm_fitment d on a.ukey_fitment = d.ukey_inventory
					and b.ukey_website = d.ukey_website
			) b on a.ukey_website = b.ukey_website
			and a.ukey_assembly = b.ukey_assembly
			and a.ukey_fitment = b.ukey_fitment
		where b.ukey_website is null
			and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and a.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' assembly fitments deleted')

	drop table #assemblyProducts

	--*******************************************************************************************************************

	-- drop table productApplications
	create table #productApplications (ukey_product int, ukey_website int, ukey_fitment int, ukey_productApplications int, ukey_productFitment int, ukey_inventory int)

	insert into #productApplications (ukey_product, ukey_website, ukey_fitment, ukey_inventory)
	select distinct b.ukey as ukey_product, b.ukey_website, e.ukey as ukey_fitment, d.ukey as ukey_inventory
		from products a (nolock)
		join websiteProducts c (nolock) on a.ukey = c.ukey_product
			and c.ukey_client = a.ukey_client
		join productFitment d (nolock) on a.ukey = d.ukey_product
			and d.ukey_client = a.ukey_client

		join AppDb.dbo.products b (nolock) on a.ukey = b.ukey_inventory
			and b.ukey_website = c.ukey_website
		join AppDb.dbo.dm_fitment e (nolock) on d.ukey_fitment = e.ukey_inventory
			and c.ukey_website = e.ukey_website

		where a.ukey_client = @nUkeyClient
			and (c.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			and c.ukey_website in (select ukey from AppDb.dbo.websites (nolock) where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' product applications found')

	update #productApplications
		set ukey_productApplications = b.ukey
		from #productApplications a
		join AppDb.dbo.productApplications b (nolock) on a.ukey_website = b.ukey_website
			and a.ukey_product = b.ukey_product
			and a.ukey_fitment = b.ukey_fitment

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' product application FK values set')

	update #productApplications
		set ukey_productFitment = b.ukey
		from #productApplications a
		join AppDb.dbo.productFitment b (nolock) on a.ukey_website = b.ukey_website
			and a.ukey_product = b.ukey_product
			and a.ukey_fitment = b.ukey_fitment

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' product fitment FK values set')

	create clustered index ix_tmp_productApplications_productApplications on #productApplications (ukey_productApplications) with fillfactor = 80
	create index ix_tmp_productApplications_productFitment on #productApplications (ukey_productFitment) with fillfactor = 80

	insert into @results (resultString) values ('Index created')

	delete AppDb.dbo.productApplications with (rowlock)
--select a.*
		from AppDb.dbo.productApplications a
		left outer join #productApplications b on a.ukey = b.ukey_productApplications

		where b.ukey_productApplications is null
			and a.ukey_website in (select ukey from AppDb.dbo.websites where ukey_client = @nUkeyClient and (ukey = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' product applications removed')

	delete AppDb.dbo.productFitment with (rowlock)
		from AppDb.dbo.productFitment a
		left outer join #productApplications b on a.ukey = b.ukey_productFitment

		where b.ukey_productFitment is null
			and a.ukey_website in (select ukey from AppDb.dbo.websites where ukey_client = @nUkeyClient and (ukey = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' product fitments removed')

	insert into AppDb.dbo.productApplications (ukey_website, ukey_product, ukey_make, ukey_model, ukey_modelyear, ukey_driveline, ukey_trimlevel, ukey_fitment)
	select a.ukey_website, a.ukey_product, e.ukey_make, e.ukey_model, e.ukey_modelYear, e.ukey_driveline, e.ukey_trimlevel, a.ukey_fitment
		from #productApplications a
		join AppDb.dbo.dm_fitment e (nolock) on a.ukey_fitment = e.ukey
		where a.ukey_productApplications is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' product applications added')

--select a.ukey_website, a.ukey_product, a.ukey_fitment, a.ukey_inventory
--	from #productApplications a
--	where a.ukey_productFitment = 0

	insert into AppDb.dbo.productFitment (ukey_website, ukey_product, ukey_fitment, ukey_inventory)
	select a.ukey_website, a.ukey_product, a.ukey_fitment, a.ukey_inventory
		from #productApplications a
		where a.ukey_productFitment is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' product fitments added')


	--*******************************************************************************************************************
	--*******************************************************************************************************************
	-- Product Options

	select distinct b.ukey_client, e.ukey_inventory as ukey_product, d.ukey_inventory as ukey_option, c.optionValue, a.ukey, convert(int, null) as ukey_inventory
		into #productOptionKeys
		from AppDb.dbo.productOptions a
		join AppDb.dbo.websites b on a.ukey_website = b.ukey
			and b.enabled = 1
		join AppDb.dbo.dm_optionValues c on a.ukey_option = c.ukey_option
			and a.ukey_optionValue = c.ukey
			and a.ukey_website = c.ukey_website
			and isnull(c.optionvalue, '') <> ''
		join AppDb.dbo.dm_options d on a.ukey_option = d.ukey
			and a.ukey_website = d.ukey_website
			and d.ukey_inventory is not null
		join AppDb.dbo.products e on a.ukey_product = e.ukey
			and a.ukey_website = e.ukey_website
			and e.ukey_inventory is not null
		where a.ukey_website in (select distinct ukey from AppDb.dbo.websites where ukey_client = @nUkeyClient)

	update #productOptionKeys
		set ukey_inventory = g.ukey
		from #productOptionKeys a
		join AppDb_inventory.dbo.productOptions g on a.ukey_client = g.ukey_client
			and a.ukey_option = g.ukey_option
			and a.ukey_product = g.ukey_product
			and isnull(g.optionValue, '') = isnull(a.optionValue, '')

	update AppDb.dbo.productOptions with (rowlock)
		set ukey_inventory = b.ukey_inventory
		from AppDb.dbo.productOptions a
		left outer join #productOptionKeys b on a.ukey = b.ukey
		where isnull(a.ukey_inventory, 0) <> isnull(b.ukey_inventory, 0)
			and a.ukey_website in (select distinct ukey from AppDb.dbo.websites where ukey_client = @nUkeyClient)

	delete AppDb.dbo.productOptions with (rowlock)
		from AppDb.dbo.productOptions a
		join #productOptionKeys b on a.ukey = b.ukey
		where b.ukey_inventory is null
			and a.ukey_website in (select distinct ukey from AppDb.dbo.websites where ukey_client = @nUkeyClient)

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' Product options removed')

	select distinct a.optionValue, b.ukey as ukey_inventory
		into #allClientOptions
		from productOptions a (nolock)
		join dm_options b (nolock) on a.ukey_option = b.ukey
			and b.ukey_client = @nUkeyClient
		where a.ukey_client = @nUkeyClient

	insert into AppDb.dbo.dm_optionValues (ukey_website, ukey_option, optionValue)
	select distinct c.ukey_website, c.ukey as ukey_option, a.optionValue
		from #allClientOptions a
		join AppDb.dbo.dm_options c (nolock) on a.ukey_inventory = c.ukey_inventory
			and c.ukey_website in (select distinct ukey from AppDb.dbo.websites where ukey_client = @nUkeyClient)
		left outer join AppDb.dbo.dm_optionValues d on c.ukey = d.ukey_option
			and c.ukey_website = d.ukey_website
			and isnull(a.optionValue, '') = isnull(d.optionValue, '')
		where d.ukey is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' Option values added')

	select a.*
		into #missingOptions
		from productOptions a (nolock)
		left outer join AppDb.dbo.productOptions b (nolock) on a.ukey = b.ukey_inventory
		where a.ukey_client = @nUkeyClient
			and b.ukey is null

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' Missing product options identified')

	insert into AppDb.dbo.productOptions (ukey_website, ukey_option, ukey_optionValue, ukey_product, ukey_inventory)
	select c.ukey_website, c.ukey, d.ukey, e.ukey, a.ukey
		from #missingOptions a
		join dm_options b (nolock) on a.ukey_option = b.ukey
		join AppDb.dbo.dm_options c (nolock) on b.ukey = c.ukey_inventory
		join AppDb.dbo.dm_optionValues d (nolock) on c.ukey = d.ukey_option
			and isnull(a.optionValue, '') = isnull(d.optionValue, '')
			and c.ukey_website = d.ukey_website
		join AppDb.dbo.products e (nolock) on a.ukey_product = e.ukey_inventory

	insert into @results (resultString) values (convert(varchar(20), @@rowcount) + ' Product options added')

	drop table #missingOptions
	drop table #allClientOptions
	drop table #productOptionKeys


	--*******************************************************************************************************************
	--*******************************************************************************************************************
	-- Product Images


	select b.ukey as ukey_product, a.imageURL, a.thumbnailURL, convert(int, 0) as sequence, a.ukey
		into #images
		from productImages a
		join AppDb.dbo.products b on a.ukey_product = b.ukey_inventory
		where a.ukey_client = @nUkeyClient

	update #images
		set sequence = 1
		from #images a
		join (
			select ukey_product, min(ukey) as ukey
				from #images
				group by ukey_product
			) b on a.ukey = b.ukey

	update #images
		set sequence = 2
		from #images a
		join (
			select ukey_product, min(ukey) as ukey
				from #images
				where sequence = 0
				group by ukey_product
			) b on a.ukey = b.ukey

	update #images
		set sequence = 3
		from #images a
		join (
			select ukey_product, min(ukey) as ukey
				from #images
				where sequence = 0
				group by ukey_product
			) b on a.ukey = b.ukey

	update AppDb.dbo.products with (rowlock)
		set image1url = b.imageURL, thumbnail1url = b.thumbnailURL
		from AppDb.dbo.products a
		join #images b on a.ukey = b.ukey_product
			and b.sequence = 1
		where isnull(a.image1url, '') <> isnull(b.imageURL, '')

	update AppDb.dbo.products with (rowlock)
		set image2url = b.imageURL, thumbnail2url = b.thumbnailURL
		from AppDb.dbo.products a
		join #images b on a.ukey = b.ukey_product
			and b.sequence = 2
		where isnull(a.image2url, '') <> isnull(b.imageURL, '')

	update AppDb.dbo.products with (rowlock)
		set image3url = b.imageURL, thumbnail3url = b.thumbnailURL
		from AppDb.dbo.products a
		join #images b on a.ukey = b.ukey_product
			and b.sequence = 3
		where isnull(a.image3url, '') <> isnull(b.imageURL, '')

	drop table #images

	--*******************************************************************************************************************

	drop table #productApplications

	select * from @results

	if @bPreview = 1
		rollback transaction updateProducts

	insert into catalogUpdateLog (ymd, logMessage)
	select ymd, resultString
		from @results
end
