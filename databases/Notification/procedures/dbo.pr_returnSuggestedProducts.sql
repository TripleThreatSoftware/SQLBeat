SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_returnSuggestedProducts 'lqna1efyykdbzjjdvfmmfgm5', 'lqna1efyykdbzjjdvfmmfgm5', 451793, 0, 12, 1, 0, 0, 0, 6
-- exec pr_returnSuggestedProducts 't0z44n55pxnc1c45gqwnktea', 't0z44n55pxnc1c45gqwnktea', 590810, 0, 12, 1, 0, 0, 0, 6
-- exec pr_returnSuggestedProducts 'zfvrnpjpy3fzdh55m1ba3b55', 'zfvrnpjpy3fzdh55m1ba3b55', 617190, 0, 12, 1, 0, 0, 0, 6
-- exec pr_returnSuggestedProducts 'cllwi0rfwztyh0mstogknwru', 'cllwi0rfwztyh0mstogknwru', 479239, 0, 12, 1, 0, 0, 0, 6
-- exec pr_returnSuggestedProducts 'cllwi0rfwztyh0mstogknwru', 'cllwi0rfwztyh0mstogknwru', 457012, 0, 12, 1, 0, 0, 0, 6

-- exec pr_returnSuggestedProducts 'faczsx551pkxarm2fuk4h155', 'faczsx551pkxarm2fuk4h155', 640798, 0, 12, 1, 0, 0, 0, 6

-- exec pr_returnSuggestedProducts '5ifpv445bviico55jrwdm1iv','5ifpv445bviico55jrwdm1iv',  null, null, 12, 0, 1, 0, 0, 10
-- exec pr_returnSuggestedProducts 'neldcxmgbsw2ovqqnbj0oh45','neldcxmgbsw2ovqqnbj0oh45',  null, null, 7, 0, 1, 0, 0, 10
-- exec pr_returnSuggestedProducts 'myqeauzlpnrfak450acb4l45','myqeauzlpnrfak450acb4l45',  null, null, 8, 0, 1, 0, 0, 10
-- exec pr_returnSuggestedProducts 'zubsfg5540qeb4mzr0n4ws45','dzmzzxjxqty1p2ykse3i4h45',  null, null, 7, 0, 1, 0, 0, 10
-- exec pr_returnSuggestedProducts 'aq43wnqg14ewna55moyfk145','kfdn3yyyxbwr535513e43kyo',  null, null, 1, 0, 1, 0, 0, 10

-- exec pr_returnSuggestedProducts '','',  655022, null, 12, 0, 1, 0, 1, 5
-- exec pr_returnSuggestedProducts '','',  659697, null, 12, 0, 1, 0, 1, 5
-- exec pr_returnSuggestedProducts '','',  447203, null, 12, 0, 1, 0, 1, 5
-- exec pr_returnSuggestedProducts '','',  53549, null, 7, 0, 1, 0, 1, 5
-- exec pr_returnSuggestedProducts '','',  439741, 8000547, 7, 0, 1, 0, 1, 5
-- exec pr_returnSuggestedProducts '','',  3693, null, 1, 0, 1, 0, 1, 5
-- exec pr_returnSuggestedProducts '','',  8459, null, 1, 0, 1, 0, 1, 5

-- exec pr_returnSuggestedProducts2 'il3reovn2wdvhlyljozls355','il3reovn2wdvhlyljozls355',  655005, null, 12, 1, 0, 0, 0, 5
-- exec pr_returnSuggestedProducts2 'hj5h00avy3gmkwyv2ujtyjy1','hj5h00avy3gmkwyv2ujtyjy1',  434508, 7877502, 7, 1, 0, 0, 0, 5

ALTER procedure [dbo].[pr_returnSuggestedProducts] (@cSessionID varchar(100), @cMachineID varchar(100), @nUkeyProduct int, @nUkeyApplication int,
	@nUkeyWebsite int, @bRelated bit = 0, @bCart bit = 0, @bPerformance bit = 0, @bAccessory bit = 0, @nNumResults int = 6)
as
begin
	set nocount on
--declare @cMachineID varchar(100)
--declare @cSessionID varchar(100)
--declare @nUkeyProduct int
--declare @bCart bit
--declare @bRelated bit
--declare @bAccessory bit
--declare @bPerformance bit
--declare @nUkeyApplication int
--declare @nUkeyWebsite int
--declare @nNumResults int


--set @nUkeyWebsite = 12
--set @nUkeyProduct = 457012
--set @bRelated = 0
--set @bAccessory = 0
--set @bCart = 1
--set @bPerformance = 0
--set @nNumResults = 6
----set @cMachineID = 'cllwi0rfwztyh0mstogknwru'
----set @cSessionID = 'cllwi0rfwztyh0mstogknwru'

--set @cMachineID = '5ifpv445bviico55jrwdm1iv'
--set @cSessionID = '5ifpv445bviico55jrwdm1iv'

	declare @dStartTime dateTime
	declare @cLookupGUID varchar(100)
	declare @nRowCount int

	set @dStartTime = getDate()
	set @cLookupGUID = newid()

	insert into suggestedProductLookups (lookupGUID, sessionID, machineID, ukey_product, ukey_application, ukey_website, isRelated, isCart, isPerformance, isAccessory, numResults) values (
		@cLookupGUID, @cSessionID, @cMachineID, @nUkeyProduct, @nUkeyApplication, @nUkeyWebsite, @bRelated, @bCart, @bPerformance, @bAccessory, @nNumResults)

	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'Starting')

	declare @cProductDescription varchar(8000)
	declare @nUkeyMake int
	declare @nUkeyModel int
	declare @nModelYear int
	declare @nUkeyModelYear int

	create table #thisCart (ukey_product int, productDescription varchar(8000), ukey_application int)
	create table #similarOrders (machineID varchar(100), sessionID varchar(100), ukey_category int)
	create table #recommendedProducts (ukey_product int, score int, productDescription varchar(8000))
	create table #models (ukey_model int, ukey_make int, ukey_modelYear int, ukey_driveline int, ukey_trimLevel int)
	create table #possibleCategories (ukey_category int)
	create table #possibleProducts (ukey_product int)
	create table #possibleAssemblies (ukey_assembly int)

	create clustered index ix_tmp_possibleCategories on #possibleCategories (ukey_category) with fillfactor = 100
	create clustered index ix_tmp_possibleAssemblies on #possibleAssemblies (ukey_assembly) with fillfactor = 100
	create clustered index ix_tmp_possibleProducts on #possibleProducts (ukey_product) with fillfactor = 100
	create clustered index ix_tmp_thisCart on #thisCart (ukey_product) with fillfactor = 80
	create clustered index ix_tmp_similarOrders on #similarOrders (machineID, sessionID, ukey_category) with fillfactor = 80

	if @bRelated = 1 or @bAccessory = 1 or @bPerformance = 1
	begin
		-- in these cases, we might could guess at an application

		if isnull(@nUkeyApplication, 0) <> 0
		begin
			select top 1
				@nUkeyMake = ukey_make,
				@nUkeyModel = a.ukey_model,
				@nModelYear = modelYear,
				@nUkeyModelYear = a.ukey_modelYear
				from productApplications a (nolock)
				join dm_modelYears b on a.ukey_modelYear = b.ukey
					and a.ukey_model = b.ukey_model
					and b.ukey_website = @nUkeyWebsite
				where a.ukey_website = @nUkeyWebsite
					and a.ukey = @nUkeyApplication
		end
		else
		begin
			if isnull(@cMachineID, '') <> ''
			begin
				select top 1
					@nUkeyMake = ukey_make,
					@nUkeyModel = ukey_model,
					@nModelYear = modelYear
					from productSearches (nolock)
					where machineID = @cMachineID
						and sessionID = @cSessionID
					order by ymd desc

				if isnull(@nUkeyMake, 0) <> 0
				begin
					set @nUkeyModelYear = (
						select top 1 a.ukey_modelYear
							from productApplications a (nolock)
							join dm_modelYears b (nolock) on a.ukey_model = b.ukey_model
								and a.ukey_modelYear = b.ukey
								and b.ukey_website = @nUkeyWebsite
								and b.modelyear = @nModelYear
							where a.ukey_make = @nUkeyMake
								and a.ukey_model = @nUkeyModel
								and a.ukey_website = @nUkeyWebsite
						)
					print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'previous search found'
					insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'previous search found')

				end
				else
				begin
					print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'no previous search found'
					insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'no previous search found')
				end

				--if not exists (
				--	select top 1 ukey
				--		from productApplications (nolock)
				--		where ukey_website = @nUkeyWebsite
				--			and ukey_product = @nUkeyProduct
				--			and ukey_make = @nUkeyMake
				--			and ukey_model = @nUkeyModel
				--			and ukey_modelYear = @nUkeyModelYear)
				--begin
				--	set @nUkeyMake = null
				--	set @nUkeyModel = null
				--	set @nModelYear = null
				--	set @nUkeyModelYear = null
				--end
			end
		end

		if isnull(@nUkeyMake, 0) <> 0 or isnull(@nUkeyModel, 0) <> 0
		begin
			insert into #models (ukey_model, ukey_modelYear, ukey_make, ukey_driveLine, ukey_trimLevel)
			select distinct a.ukey_model, a.ukey_modelYear, a.ukey_make, a.ukey_driveLine, a.ukey_trimLevel
				from lk_productApplicationsUsed a (nolock)
				where (ukey_make = @nUkeyMake or isnull(@nUkeyMake, 0) = 0)
					and (ukey_model = @nUkeyModel or isnull(@nUkeyModel, 0) = 0)
					and (ukey_modelYear = @nUkeyModelYear or isnull(@nUkeyModelYear, 0) = 0)
					and a.ukey_website = @nUkeyWebsite

			set @nRowCount = @@rowcount
			print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'added ' + convert(varchar(20), @nRowCount) + ' applications, based on search'
			insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'added ' + convert(varchar(20), @nRowCount) + ' applications, based on search')

		end

		if isnull(@nUkeyProduct, 0) = 0 and isnull(@nUkeyApplication, 0) <> 0
			set @nUkeyProduct = (select ukey_product from productApplications (nolock) where ukey = @nUkeyApplication)

		set @cProductDescription = (select top 1 productDescription from products (nolock) where ukey_website = @nUkeyWebsite and ukey = @nUkeyProduct)

		print 'This product: ' + @cProductDescription

		insert into #thisCart (ukey_product, productDescription, ukey_application)
		select distinct a.ukey as ukey_product, productDescription, @nUkeyApplication
			from products a (nolock)
			where a.ukey = @nUkeyProduct
				and a.ukey_website = @nUkeyWebsite

	end
	if @bCart = 1
	begin
		insert into #thisCart (ukey_product, productDescription, ukey_application)
		select a.ukey as ukey_product, productDescription, e.ukey_application
			from products a (nolock)
			join cart e (nolock) on a.ukey = e.ukey_product
				and e.sessionID = @cSessionID
				and e.machineID = @cMachineID
			where a.ukey_website = @nUkeyWebsite

		set @nRowCount = @@rowcount
		print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'added ' + convert(varchar(20), @nRowCount) + ' items from the cart'
		insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'added ' + convert(varchar(20), @nRowCount) + ' items from the cart')
	end

	insert into #similarOrders (machineID, sessionID)
	select distinct a.machineID, a.sessionID
		from cart a (nolock)
		join #thisCart b on a.ukey_product = b.ukey_product
		where machineID <> @cMachineID

	set @nRowCount = @@rowcount
	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'identified ' + convert(varchar(20), @nRowCount) + ' purchases of this item'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'identified ' + convert(varchar(20), @nRowCount) + ' purchases of this item')

	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- go into cart history and see what else people bought along with this item
	insert into #recommendedProducts (ukey_product, score, productDescription)
	select
		a.ukey_product,
		100 as score,
		c.productDescription
		from cart a (nolock)
		join #similarOrders b on a.machineID = b.machineID
			and a.sessionID = b.sessionID
		join products c (nolock) on a.ukey_product = c.ukey
			and c.ukey_website = @nUkeyWebsite
			and c.enabled = 1
		where a.machineID <> @cMachineID
		group by a.ukey_product, c.productDescription
		having count(distinct a.machineID) > 1

	set @nRowCount = @@rowcount
	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'identified ' + convert(varchar(20), @nRowCount) + ' other things people bought'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'identified ' + convert(varchar(20), @nRowCount) + ' other things people bought')

	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- From here down, we need to filter products based on fitment


	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- establish possible fitments to filter products
	if (select count(*) from #models) = 0
	begin
		insert into #models (ukey_model, ukey_modelYear, ukey_make, ukey_driveline, ukey_trimlevel)
		select top 150 a.*
			from (
				select distinct ukey_model, ukey_modelyear, ukey_make, ukey_driveline, ukey_trimlevel
					from #thisCart a (nolock)
					join productApplications b (nolock) on a.ukey_product = b.ukey_product
						and (a.ukey_application = b.ukey or isnull(a.ukey_application, 0) = 0)
						and b.ukey_website = @nUkeyWebsite
				) a
			left outer join lk_popularModels b (nolock) on a.ukey_model = b.ukey_model
				and a.ukey_make = b.ukey_make
				and b.ukey_website = @nUkeyWebsite
			order by b.modelScore desc

		set @nRowCount = @@rowcount
		print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'identified ' + convert(varchar(20), @nRowCount) + ' models this product fits'
		insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'identified ' + convert(varchar(20), @nRowCount) + ' models this product fits')
	end

	insert into #models (ukey_make, ukey_model, ukey_modelYear, ukey_driveline, ukey_trimlevel)
	select distinct a.ukey_make, a.ukey_model, a.ukey_modelYear, a.ukey_driveline, a.ukey_trimlevel
		from lk_productApplicationsUsed a (nolock)
		join #models b on (a.ukey_make = b.ukey_make or a.ukey_make = 0)
			and (a.ukey_model = b.ukey_model or a.ukey_model = 0)
			and (a.ukey_modelYear = b.ukey_modelYear or a.ukey_modelYear = 0)
			and (a.ukey_driveLine = b.ukey_driveLine or a.ukey_driveLine = 0)
			and (a.ukey_trimLevel = b.ukey_trimLevel or a.ukey_trimLevel = 0)
		left outer join #models c on a.ukey_make = c.ukey_make
			and a.ukey_model = c.ukey_model
			and a.ukey_modelYear = c.ukey_modelYear
			and a.ukey_driveLine = c.ukey_driveLine
			and a.ukey_trimLevel = c.ukey_trimLevel
		where c.ukey_make is null
			and a.ukey_website = @nUkeyWebsite

	set @nRowCount = @@rowcount
	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'added ' + convert(varchar(20), @nRowCount) + ' possible generic fitments'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID,  'added ' + convert(varchar(20), @nRowCount) + ' possible generic fitments')

	create clustered index ix_tmp_models on #models (ukey_modelYear, ukey_model, ukey_make, ukey_driveline, ukey_trimlevel) with fillfactor = 100

	if (select count(*) from #models) > 200
	begin
		delete #models
			from #models a
			left outer join (
				select top 200 a.ukey_make, a.ukey_model, a.ukey_modelYear, a.ukey_driveLine, a.ukey_trimLevel
					from #models a
					left outer join lk_popularModels b (nolock) on a.ukey_make = b.ukey_make
						and a.ukey_model = b.ukey_model
					order by b.modelScore desc
				) b on a.ukey_make = b.ukey_make
					and a.ukey_model = b.ukey_model
					and a.ukey_modelYear = b.ukey_modelYear
					and a.ukey_driveLine = b.ukey_driveLine
					and a.ukey_trimLevel = b.ukey_trimLevel
			where b.ukey_make is null

		set @nRowCount = @@rowcount
		print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'removed ' + convert(varchar(20), @nRowCount) + ' of the least popular models'
		insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID,  'removed ' + convert(varchar(20), @nRowCount) + ' of the least popular models')
	end

	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'indexed model list'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'indexed model list')

	if @bRelated = 1 or @bCart = 1
	begin
		--*********************************************************************************************************************************************
		--*********************************************************************************************************************************************
		-- look at other products in the same assembly which share fitment with this product
		insert into #possibleAssemblies (ukey_assembly)
		select distinct a.ukey_assembly
			from assemblyProducts a (nolock)
			join #thisCart b on a.ukey_product = b.ukey_product
			where a.ukey_website = @nUkeyWebsite

		set @nRowCount = @@rowcount
		print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'found ' + convert(varchar(20), @nRowCount) + ' related assemblies'
		insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'found ' + convert(varchar(20), @nRowCount) + ' related assemblies')

		if @nRowCount < 10 and @nRowCount > 0
		begin
			insert into #recommendedProducts (ukey_product, score)
			select distinct a.ukey_product, 75 as score
				from (
					select distinct ukey_product
						from assemblyProducts a (nolock)
						join #possibleAssemblies b on a.ukey_assembly = b.ukey_assembly
						where a.ukey_website = @nUkeyWebsite
					) a
				join productApplications b (nolock) on a.ukey_product = b.ukey_product
					and b.ukey_website = @nUkeyWebsite
				join #models c on b.ukey_make = c.ukey_make
					and b.ukey_model = c.ukey_model
					and b.ukey_modelYear = c.ukey_modelYear
					and b.ukey_trimLevel = c.ukey_trimLevel
					and b.ukey_driveLine = c.ukey_driveLine

			set @nRowCount = @@rowcount
			print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'found ' + convert(varchar(20), @nRowCount) + ' other products in related assemblies'
			insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'found ' + convert(varchar(20), @nRowCount) + ' other products in related assemblies')
		end
		else
		begin
			print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'ignored related assemblies'
			insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'ignored related assemblies')
		end

		--*********************************************************************************************************************************************
		--*********************************************************************************************************************************************
		-- if we couldn't find enough products, look at products within the same categories as items in the basket
		if (select count(*) from #recommendedProducts) < 10
		begin
			insert into #possibleProducts (ukey_product)
			select distinct b.ukey_product
				from #models a
				join productApplications b (nolock) on b.ukey_website = @nUkeyWebsite
					and a.ukey_model = b.ukey_model
					and a.ukey_modelYear = b.ukey_modelYear
					and a.ukey_make = b.ukey_make
					and a.ukey_trimLevel = b.ukey_trimLevel
					and a.ukey_driveLine = b.ukey_driveLine

			set @nRowCount = @@rowcount
			print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'populated ' + convert(varchar(20), @nRowCount) + ' possible products'
			insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'populated ' + convert(varchar(20), @nRowCount) + ' possible products')

			insert into #possibleCategories (ukey_category)
			select distinct ukey_category
				from productCategories a (nolock)
				join #thisCart b on a.ukey_product = b.ukey_product
				where a.ukey_website = @nUkeyWebsite

			set @nRowCount = @@rowcount
			print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'populated ' + convert(varchar(20), @nRowCount) + ' possible categories'
			insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'populated ' + convert(varchar(20), @nRowCount) + ' possible categories')

			insert into #recommendedProducts (ukey_product, score)
			select top 20 a.ukey_product, sum(c.numHits+b.numHits) as numWords
				from (
					select distinct a.ukey_product
						from #possibleProducts a
						join productCategories c (nolock) on a.ukey_product = c.ukey_product
							and c.ukey_website = @nUkeyWebsite
						join #possibleCategories d on c.ukey_category = d.ukey_category
					) a
				join lk_productWords c (nolock) on a.ukey_product = c.ukey_product
					and c.ukey_website = @nUkeyWebsite
				join (
					select word, sum(numHits) as numHits
						from #thisCart a
						join lk_productWords b (nolock) on a.ukey_product = b.ukey_product
							and b.ukey_website = @nUkeyWebsite
						group by word
					) b on b.word = c.word
				group by a.ukey_product
				having count(*) > 0
				order by count(*) desc

			set @nRowCount = @@rowcount
			print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'identified ' + convert(varchar(20), @nRowCount) + ' related products within the category, using words'
			insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'identified ' + convert(varchar(20), @nRowCount) + ' related products within the category, using words')

			--*********************************************************************************************************************************************
			--*********************************************************************************************************************************************
			-- if there's still nothing, look at all products regardless of category
			if (select count(*) from #recommendedProducts) < 10
			begin
				insert into #recommendedProducts (ukey_product, score)
				select top 20 a.ukey_product, count(*) as numWords
					from #possibleProducts a
					join lk_productWords c (nolock) on a.ukey_product = c.ukey_product
						and c.ukey_website = @nUkeyWebsite
					join (
						select word
							from #thisCart a
							join lk_productWords b (nolock) on a.ukey_product = b.ukey_product
								and b.ukey_website = @nUkeyWebsite
						) b on b.word = c.word
					group by a.ukey_product
					having count(*) > 0
					order by count(*) desc

				set @nRowCount = @@rowcount
				print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'identified ' + convert(varchar(20), @nRowCount) + ' related products regardless of category, using words'
				insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'identified ' + convert(varchar(20), @nRowCount) + ' related products regardless of category, using words')
			end

			--*********************************************************************************************************************************************
			--*********************************************************************************************************************************************
			-- and failing all that, look at any related product by product score
			if (select count(*) from #recommendedProducts) < 10
			begin
				insert into #recommendedProducts (ukey_product, score)
				select top 20 a.ukey_product, b.productScore
					from #possibleProducts a
					join lk_popularProducts b (nolock) on a.ukey_product = b.ukey_product
						and b.ukey_website = @nUkeyWebsite
					order by b.productScore desc

				set @nRowCount = @@rowcount
				print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'identified ' + convert(varchar(20), @nRowCount) + ' related products regardless of category, using product scores'
				insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'identified ' + convert(varchar(20), @nRowCount) + ' related products regardless of category, using product scores')
			end

		end

	end

	if @bAccessory = 1 or @bCart = 1
	begin
		if (select count(*) from #possibleProducts) = 0
		begin
			insert into #possibleProducts (ukey_product)
			select distinct b.ukey_product
				from #models a
				join productApplications b (nolock) on b.ukey_website = @nUkeyWebsite
					and (a.ukey_model = b.ukey_model)
					and (a.ukey_modelYear = b.ukey_modelYear)
					and (a.ukey_make = b.ukey_make)
					and a.ukey_trimLevel = b.ukey_trimLevel
					and a.ukey_driveLine = b.ukey_driveLine

			set @nRowCount = @@rowcount
			print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'populated ' + convert(varchar(20), @nRowCount) + ' possible products'
			insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'populated ' + convert(varchar(20), @nRowCount) + ' possible products')
		end

		--*********************************************************************************************************************************************
		--*********************************************************************************************************************************************
		-- look at accessory tagged products that match fitment
		insert into #recommendedProducts (ukey_product, score)
		select top 20 a.ukey_product, 50 as score
			from #possibleProducts a
			left outer join lk_popularProducts b (nolock) on a.ukey_product = b.ukey_product
				and b.ukey_website = @nUkeyWebsite
			join products c (nolock) on a.ukey_product = c.ukey
				and c.ukey_website = @nUkeyWebsite
				and c.enabled = 1
				and c.isAccessory = 1
			order by isnull(b.productScore, 0) desc

		set @nRowCount = @@rowcount
		print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'added ' + convert(varchar(20), @nRowCount) + ' accessories'
		insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'added ' + convert(varchar(20), @nRowCount) + ' accessories')
	end

	if @bPerformance = 1 or @bCart = 1
	begin
		if (select count(*) from #possibleProducts) = 0
		begin
			insert into #possibleProducts (ukey_product)
			select distinct b.ukey_product
				from #models a
				join productApplications b (nolock) on b.ukey_website = @nUkeyWebsite
					and (a.ukey_model = b.ukey_model)
					and (a.ukey_modelYear = b.ukey_modelYear)
					and (a.ukey_make = b.ukey_make)
					and a.ukey_trimLevel = b.ukey_trimLevel
					and a.ukey_driveLine = b.ukey_driveLine

			set @nRowCount = @@rowcount
			print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'populated ' + convert(varchar(20), @nRowCount) + ' possible products'
			insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'populated ' + convert(varchar(20), @nRowCount) + ' possible products')
		end

		--*********************************************************************************************************************************************
		--*********************************************************************************************************************************************
		-- look at accessory tagged products that match fitment
		insert into #recommendedProducts (ukey_product, score)
		select top 20 a.ukey_product, 50 as score
			from #possibleProducts a
			left outer join lk_popularProducts b (nolock) on a.ukey_product = b.ukey_product
				and b.ukey_website = @nUkeyWebsite
			join products c (nolock) on a.ukey_product = c.ukey
				and c.ukey_website = @nUkeyWebsite
				and c.enabled = 1
				and c.isPerformance = 1
			order by isnull(b.productScore, 0) desc

		set @nRowCount = @@rowcount
		print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'added ' + convert(varchar(20), @nRowCount) + ' performance parts'
		insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'added ' + convert(varchar(20), @nRowCount) + ' performance parts')
	end


	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- now, we move into selecting from among the recommendations

	create index ix_tmp_recommendedProducts_product on #recommendedProducts (ukey_product, score) with fillfactor = 60

	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'indexed recommended products'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'indexed recommended products')

--select a.* , b.productDescription
--	from #recommendedProducts a
--	join products b (nolock) on a.ukey_product = b.ukey
--		and b.ukey_website = @nUkeyWebsite
--	order by score desc

--select * from #models
--select * from #possibleCategories
--select * from #possibleProducts

	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- remove all but the 20 most likely
	delete #recommendedProducts
		from #recommendedProducts a
		left outer join (
			select top 20 ukey_product
				from #recommendedProducts
				order by score desc
			) b on a.ukey_product = b.ukey_product
		where b.ukey_product is null

	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'removed all but top 20'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'removed all but top 20')

	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- remove items that are already in the basket
	delete #recommendedProducts
		from #recommendedProducts a
		join #thisCart b on a.ukey_product = b.ukey_product

	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'removed items that are already in the basket'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'removed items that are already in the basket')

	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- randomize
	declare @nCounter int
	set @nCounter = 0

	while exists (select top 1 ukey_product from #recommendedProducts where ukey_product > @nCounter)
	begin
		select top 1 @nCounter = ukey_product
			from #recommendedProducts
			where ukey_product > @nCounter
			order by ukey_product

		update #recommendedProducts
			set score = convert(int, rand() * 100)
			where ukey_product = @nCounter
	end

	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'randomized resultset'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'randomized resultset')

	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- select results to return
	select top(@nNumResults)
		a.ukey,
		a.stockCode,
		a.productDescription,
		a.price,
		a.listPrice,
		b.score,
		case when isnull(a.thumbnail1url, '') = '' then a.image1URL else a.thumbnail1URL end as imageURL,
		dbo.fn_returnRewrittenProductURL(b.ukey_product, 0, '', '', '', a.productDescription, a.stockCode) as productURL,
		convert(varchar(20), a.ukey) + '|' as keyString,
		convert(varchar(8000), '') as categoryList,
		convert(varchar(8000), '') as assemblyList,
		convert(varchar(8000), '') as [application]
		into #results
		from products a (nolock)
		join (select ukey_product, max(score) as score from #recommendedProducts group by ukey_product) b on a.ukey = b.ukey_product
		where a.ukey_website = @nUkeyWebsite
			and a.enabled = 1
		order by score desc

	create index ix_tmp_results_product on #results (ukey) with fillfactor = 80

	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'selected results to return'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'selected results to return')

	--*********************************************************************************************************************************************
	--*********************************************************************************************************************************************
	-- from here down, we add detail to the selected results
	update #results
		set imageURL = c.thumbnail1URL
		from #results a
		join productOptions b (nolock) on a.ukey = b.ukey_product
			and b.ukey_website = @nUkeyWebsite
		join dm_optionValues c (nolock) on b.ukey_option = c.ukey_option
			and c.ukey = b.ukey_optionValue
			and isnull(c.image1url, '') <> ''
			and c.ukey_website = @nUkeyWebsite
		where isnull(a.imageURL, '') = ''

	update #results
		set imageURL = c.thumbnailURL
		from #results a
		join assemblyProducts b (nolock) on a.ukey = b.ukey_product
			and b.ukey_website = @nUkeyWebsite
		join assemblyImages c (nolock) on b.ukey_assembly = c.ukey_assembly
			and c.ukey_website = @nUkeyWebsite
			and isnull(c.thumbnailURL, '') <> ''
		where isnull(a.imageURL, '') = ''

	update #results
		set imageURL = case when isnull(c.thumbnailURL, '') = '' then '/images/singlepixel.gif' else c.thumbnailURL end
		from #results a
		left outer join assemblyProducts b (nolock) on a.ukey = b.ukey_product
			and b.ukey_website = @nUkeyWebsite
		left outer join assemblies c (nolock) on b.ukey_assembly = c.ukey
			and c.ukey_website = @nUkeyWebsite
			and isnull(c.thumbnailURL, '') <> ''
		where isnull(a.imageURL, '') = ''

	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'images set'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'images added')

	update #results
		set assemblyList = b.assemblyList --case when len(b.assemblyList) > 500 then 'Hardware Part' else b.assemblyList end
		from #results a
		join lk_productAssemblies b (nolock) on a.ukey = b.ukey_product
			and b.ukey_website = @nUkeyWebsite

	update #results
		set categoryList = b.categoryList -- case when len(b.categoryList) > 500 then 'Hardware Part' else b.categoryList end
		from #results a
		join lk_productCategories b (nolock) on a.ukey = b.ukey_product
			and b.ukey_website = @nUkeyWebsite

	update #results
		set application = isnull(b.applicationString, '')
		from #results a
		left outer join lk_productApplicationStrings (nolock) b on a.ukey = b.ukey_product
			and b.ukey_website = @nUkeyWebsite

	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'strings set'

	select *,
		imageURL as thumbnailURL,
		'' as additionalNotes,
		'' as saleImage
		from #results

	set @nRowCount = @@rowcount
	print convert(varchar(20), dateDiff(ms, @dStartTime, getdate()), 120) + ': ' + 'returned ' + convert(varchar(20), @nRowCount) + ' results'
	insert into suggestedProductLookupTiming (lookupGUID, timingMessage) values (@cLookupGUID, 'returned ' + convert(varchar(20), @nRowCount) + ' results')

	drop table #results
	drop table #recommendedProducts
	drop table #thisCart
	drop table #similarOrders
	drop table #models
	drop table #possibleCategories
	drop table #possibleProducts
	drop table #possibleAssemblies
end
