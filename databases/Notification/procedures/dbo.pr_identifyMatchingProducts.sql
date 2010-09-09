SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--select top 100 * from cachedSearches (nolock) where ukey_website = 12 order by ukey desc
--delete from cachedSearchResults where ukey_search in (1011, 1010)
--delete from cachedSearches where ukey in (1011, 1010)

-- exec pr_identifyMatchingProducts '', '', 0, 0, 1991, 0, 3, 0, 'front suspension bushing'
-- exec pr_identifyMatchingProducts '', '', 8, 0, 0, 0, 1, 0, 'brake pads'
-- exec pr_identifyMatchingProducts '', '', 93, 1153, 1970, '', 0, 8, 25, 0
-- exec pr_identifyMatchingProducts '', '', 0, 0, 0, '', 0, 1, 25, 0
-- exec pr_identifyMatchingProducts '', '', 8, 102, 0, '', 0, 1, 25, 0
-- exec pr_identifyMatchingProducts '', '', 0, 0, 0, '', 330, 1, 25, 0
-- exec pr_identifyMatchingProducts '', '', 5, 71, 0, 0, 1, 0, 'seat covers'
-- exec pr_identifyMatchingProducts '', '', 2, 105, 1960, 'floor', 0, 1, 25, 0
-- exec pr_identifyMatchingProducts '', '', 2, 105, 0, 'running lights', 0, 1, 25, 0
-- exec pr_identifyMatchingProducts '', '', 0, 0, 0, '', 1877, 8, 50, 0
-- exec pr_identifyMatchingProducts '', '', 223, 4680, 0, '', 0, 8, 50, 0
-- exec pr_identifyMatchingProducts '', '', 207, 0, 0, 'trunk board', 0, 8, 50, 0
-- exec pr_identifyMatchingProducts '', '', 8, 0, 0, '', 0, 1, 50, 0
-- exec pr_identifyMatchingProducts '', '', 8, 0, 0, 'test', 0, 1, 50, 0
-- exec pr_identifyMatchingProducts '', '', 8, 0, 0, '', 0, 1, 50, 0
-- exec pr_identifyMatchingProducts '', '', 8, 0, 1952, '', 0, 1, 50, 0
-- exec pr_identifyMatchingProducts '', '', 8, 101, 1968, 'interior', 0, 1, 50, 0
-- exec pr_identifyMatchingProducts '', '', 8, 101, 1974, 0, 1, 0, ''
-- exec pr_identifyMatchingProducts '', '', 8, 101, 1974, '', 29, 1, 50, 0
-- exec pr_identifyMatchingProducts '', '', 207, 0, 0, '', 0, 8, 50, 0
-- exec pr_identifyMatchingProducts '', '', 207, 4667, 0, 'door felts', 0, 8, 50, 0
-- exec pr_identifyMatchingProducts '', '', 8, 101, 0, '', 0, 1, 50, 0
-- exec pr_identifyMatchingProducts '', '', 2, 105, 0, 'leaf spring', 0, 1, 50, 0
-- exec pr_identifyMatchingProducts '', '', 266, 3471, 1978, 'MW00101', 1978, 8, 50, 0

-- exec pr_identifyMatchingProducts '', '', 8, 102, 0, 2331, 1, 0, ''

-- exec pr_identifyMatchingProducts2 '', '', 0, 0, 0, 0, 3, 0, 'evolution cloth cockpit covers'
-- exec pr_identifyMatchingProducts2 '', '', 2, 105, 0, 0, 1, 0, 'leaf springs'

--truncate table cachedSearches
--truncate table cachedSearchResults
--truncate table searchTiming

-- select * from searchTiming where ukey_Search = 2 order by ukey
-- exec pr_identifyMatchingProducts2 '', '', 5, 71, 0, 0, 1, 0, 'tie rod end'
-- exec pr_identifyMatchingProducts '', '', 5, 71, 0, 0, 1, 0, 'tierod', -2
-- exec pr_identifyMatchingProducts2 '', '', 2, 105, 0, 0, 1, 0, 'leaf spring', -2
-- exec pr_identifyMatchingProducts2 '', '', 8, 101, 0, 0, 1, 0, 'rims'
-- exec pr_identifyMatchingProducts2 '', '', 8, 101, 1968, 0, 1, 0, 'interior'
-- exec pr_identifyMatchingProducts2 '', '', 8, 0, 0, 0, 1, 0, 'brake pads'

-- exec pr_identifyMatchingProducts2 '', '', 207, 4667, 0, 0, 8, 0, 'door felts'
-- exec pr_identifyMatchingProducts2 '', '', 207, 4667, 0, 0, 8, 0, 'window felts'
-- exec pr_identifyMatchingProducts2 '', '', 207, 4667, 0, 0, 8, 0, 'door seal'
-- exec pr_identifyMatchingProducts2 '', '', 207, 4667, 0, 0, 8, 0, 'door weather strip'

-- exec pr_identifyMatchingProducts2 '', '', 336, 5875, 2003, 2047, 7, 0, 'exhaust valve', 1
-- exec pr_identifyMatchingProducts '', '', 336, 5875, 2003, 2047, 7, 0, 'intake valve', 1
-- exec pr_identifyMatchingProducts '', '', 0, 0, 2003, 0, 7, 0, 'dip stick', 1
-- exec pr_identifyMatchingProducts2 '', '', 0, 0, 2002, 0, 7, 0, 'dip stick', 1
-- exec pr_identifyMatchingProducts2 '', '', 0, 0, 1967, 0, 1, 0, 'exhaust valve', 1

-- exec pr_identifyMatchingProducts '', '', 8, 101, 1972, 70, 1, 0, '', 0

-- exec pr_identifyMatchingProducts2 '', '', 0, 0, 0, 0, 12, 0, '', 0
-- exec pr_identifyMatchingProducts2 '', '', 381, 0, 1998, 0, 12, 0, '540 door handle', 1, 0, 0
-- exec pr_identifyMatchingProducts2 '', '', 381, 0, 1998, 0, 12, 0, '', 1
-- exec pr_identifyMatchingProducts2 '', '', 88, 0, 0, 1852, 7, 0, '', -2
-- exec pr_identifyMatchingProducts '', '', 88, 0, 0, 1852, 7, 0, '', 2
-- exec pr_identifyMatchingProducts2 '', '', 0, 0, 0, 0, 12, 0, 'polo shirt', 1, 0, 0

-- exec pr_identifyMatchingProducts2 '', '', 380, 0, 0, 0, 12, 0, '"coil pack"', 1, 0, 0
-- exec pr_identifyMatchingProducts2 '', '', 387, 7436, 0, 0, 12, 0, '"front seat" black', 1, 0, 0
-- exec pr_identifyMatchingProducts2 '', '', 387, 7436, 0, 0, 12, 0, '"front seat"', 1, 0, 0

-- exec pr_identifyMatchingProducts2 '', '', 2, 105, 1967, 0, 1, 0, 'clutch', 1, 0, 0
-- exec pr_identifyMatchingProducts2 '', '', 2, 105, 1967, 0, 1, 0, 'clutch disc', 1, 0, 0

-- exec pr_identifyMatchingProducts2 '', '', 387, 7436, 1998, 0, 12, 0, 'water pump', 1, 55, 0

-- exec pr_identifyMatchingProducts2 '', '', 379, 7493, 0, 0, 12, 0, 'rear view mirror', 1, 0, 0

-- exec pr_identifyMatchingProducts2 '', '', 387, 7436, 1998, 0, 12, 0, 'oil filter', 1, 55, 355

-- exec pr_identifyMatchingProducts2 '', '', 380, 0, 0, 0, 12, 0, 'headlight', 1, 0, 0
-- exec pr_identifyMatchingProducts2 '', '', 8, 101, 0, 0, 1, 0, 'oil filter', 1, 0, 0
-- exec pr_identifyMatchingProducts '', '', 0, 0, 0, 0, 8, 0, 'sb 34', 1, 0, 0
-- exec pr_identifyMatchingProducts2 '', '', 0, 0, 0, 0, 12, 0, 'reflection panel', -2, 0, 0
-- exec pr_identifyMatchingProducts2 '', '', 5, 71, 0, 0, 1, 0, 'seat covers', -2
-- exec pr_identifyMatchingProducts2 '', '', 8, 101, 0, 0, 1, 0, 'seat covers', -2
-- exec pr_identifyMatchingProducts2 '', '', 387, 7436, 1998, 0, 12, 0, 'water pump', -2, 55, 355

-- exec pr_identifyMatchingProducts '', '', 0, 0, 0, 3114, 8, 0, '', -2, 0, 0
-- exec pr_identifyMatchingProducts '', '', 207, 0, 0, 3114, 8, 0, '', -2, 0, 0

-- exec pr_identifyMatchingProducts '', '', 0, 0, 0, 0, 14, 0, '72601921385', -2, 0, 0
-- exec pr_identifyMatchingProducts '', '', 0, 0, 0, 0, 12, 0, '61677179311', -2, 0, 0


--ukey_make=383&ukey_model=7451&modelYear=2005&ukey_category=0&ukey_driveline=0&ukey_trimlevel=432&ukey_modelRange=0&isOnSale=0&searchTerm=Crankcase%20Ventilation%20valve

--delete from cachedSearches where ukey = 4969
--delete from cachedSearchResults where ukey_Search = 4969
--delete from cachedSearchFitments where ukey_Search = 4969
--delete from searchTiming where ukey_search = -2
--select * from searchTiming (nolock) where ukey_search = -2 order by ukey
-- select count(*) from dm_modelRangeFitments where ukey_modelRange = 305
-- select * from products where productDescription like '%coil pack%' and ukey_website = 12

ALTER procedure [dbo].[pr_identifyMatchingProducts] (@cSessionID varchar(100), @cMachineID varchar(100),
	@nUkeyMake int, @nUkeyModel int, @nModelYear int, @nUkeyCategory int, @nUkeyWebsite int = 1, @bIsOnSale bit = 0, @cSearchString varchar(5000), @nUkeyIncomingSearch int = 0,
	@nUkeyDriveLine int = 0, @nUkeyTrimLevel int = 0, @nUkeyModelRange int = 0)
as
begin
	declare @cLogMessage varchar(2000)
	declare @searchTiming table (ukey_search int, ymd dateTime default getDate(), message varchar(8000))

	if @nUkeyIncomingSearch <> 0
	begin
		set @cLogMessage = 'Identify has been called'
		insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
	end

	declare @bPreferenceBasedOnWordPosition bit

	set @bPreferenceBasedOnWordPosition = 1

	declare @nUkeySearch bigint
	declare @bPerformSearch bit
	declare @bSearchTerms bit
	declare @bSaveResults bit
	declare @cSQLString nvarchar(4000)
	declare @cWord varchar(100)
	declare @nMinScore int
	declare @nMaxScore decimal(20,4)
	declare @nRowCount int
	declare @bIncludeCategory bit
	declare @cCategoryName varchar(500)
	declare @nNumWords int
	declare @cAllSearchWords nvarchar(4000)
	declare @cAllSearchWords_and nvarchar(4000)
	declare @bNoFitmentSupplied bit
	declare @nNumMakes int
	declare @nNumModels int

	set @nNumMakes = (select count(*) from dm_makes (nolock) where ukey_website = @nUkeyWebsite and showOnHomePage = 1)
	set @nNumModels = (select count(*) from dm_models (nolock) where ukey_website = @nUkeyWebsite and enabled = 1)

	create table #matchingProducts (ukey_product int, ukey_application int, score int, secondaryScore int, numWords int, numWords_anywhere int, wordPosition int, containsFullPhrase bit)
	declare @searchWords table (searchWord varchar(100), wordScore int, occurs int, scoreBias int, categoryScore int, modifiedWord varchar(100), isOriginal bit)

	set @bPerformSearch = 1
	set @bNoFitmentSupplied = 0

	if isnull(@cSearchString, '') <> ''
		set @bSearchTerms = 1
	else
		set @bSearchTerms = 0

	set @bSaveResults = 1
	set @nUkeyIncomingSearch = isnull(@nUkeyIncomingSearch, 0)
	set @nNumWords = 0

	set nocount on

	declare @fitment table (ukey_fitment int)

	set @nUkeyMake = isnull(@nUkeyMake, 0)
	set @nUkeyModel = isnull(@nUkeyModel, 0)
	set @nModelYear = isnull(@nModelYear, 0)
	set @nUkeyTrimLevel = isnull(@nUkeyTrimLevel, 0)
	set @nUkeyDriveLine = isnull(@nUkeyDriveLine, 0)
	set @nUkeyCategory = isnull(@nUkeyCategory, 0)
	set @nUkeyModelRange = isnull(@nUkeyModelRange, 0)
	set @cSearchString = rtrim(ltrim(@cSearchString))

	if isnull(@nUkeyCategory, 0) <> 0
		set @cCategoryName = (select top 1 categoryName from dm_categories (nolock) where ukey_website = @nUkeyWebsite and ukey = @nUkeyCategory)

	-- *************************************************************************
	-- begin caching

	set @nUkeySearch = (
		select top 1 ukey
			from cachedSearches (nolock)
			where ukey_website = @nUkeyWebsite
				and isnull(@nUkeyMake, 0) = isnull(ukey_make, 0)
				and isnull(@nUkeyModel, 0) = isnull(ukey_model, 0)
				and isnull(@nModelYear, 0) = isnull(modelYear, 0)
				and isnull(@nUkeyCategory, 0) = isnull(ukey_category, 0)
				and isnull(@bIsOnSale, 0) = isnull(isOnSale, 0)
				and isnull(@cSearchString, '') = isnull(searchString, '')
				and isnull(@nUkeyDriveLine, 0) = isnull(ukey_driveLine, 0)
				and isnull(@nUkeyTrimLevel, 0) = isnull(ukey_trimLevel, 0)
				and isnull(@nUkeyModelRange, 0) = isnull(ukey_modelRange, 0)
		)

	if @nUkeySearch is not null
	begin
		print 'Found cached search #' + convert(varchar(20), @nUkeySearch)

		if @nUkeyIncomingSearch <> 0
		begin
			set @cLogMessage = 'Found cached search #' + convert(varchar(20), @nUkeySearch)
			insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
		end

		insert into #matchingProducts (ukey_product, ukey_application, score)
		select ukey_product, ukey_application, score
			from cachedSearchResults (nolock)
			where ukey_search = @nUkeySearch
				and ukey_website = @nUkeyWebsite

		set @bPerformSearch = 0
		set @bSearchTerms = 0
		set @bSaveResults = 0
	end

	-- if we don't have quite the results we want,
	if @bPerformSearch = 1
	begin

		if @nUkeyIncomingSearch <> 0
		begin
			set @cLogMessage = 'A search is being performed'
			insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
		end

		-- *************************************************************************
		-- begin regular search

		declare @possibleProducts table (ukey_product int)

		if isnull(@cSearchString, '') <> ''
		begin
			insert into @possibleProducts (ukey_product)
			select ukey
				from products (nolock)
				where enabled = 1
					and (
						stockCode = replace(@cSearchString, '"', '')
						or replace(stockCode, ' ', '') = replace(replace(@cSearchString, '"', ''), ' ', '')
						or isnull(altCode1, '') = replace(@cSearchString, '"', '')
						or replace(isnull(altCode1, ''), ' ', '') = replace(replace(@cSearchString, '"', ''), ' ', '')
						)
					and ukey_website = @nUkeyWebsite

			insert into @possibleProducts (ukey_product)
			select ukey_product
				from alternateStockCodes (nolock)
				where (
						stockCode = replace(@cSearchString, '"', '')
						or replace(stockCode, ' ', '') = replace(replace(@cSearchString, '"', ''), ' ', '')
						)
					and ukey_website = @nUkeyWebsite
		end

		if (select count(*) from @possibleProducts) > 0
		begin
			insert into #matchingProducts (ukey_product)
			select distinct ukey_product
				from @possibleProducts

			if @nUkeyIncomingSearch <> 0
			begin
				set @cLogMessage = 'Found a stock code'
				insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			end

			set @bSearchTerms = 0
		end
		else
		begin
			--**********************************************************************************************************************************
			--**********************************************************************************************************************************
			-- now, look at the search string

			if @bSearchTerms = 1
			begin

				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = 'Refining search based on terms'
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end

				if isnull(@cSearchString, '') <> ''
				begin
					set @bIncludeCategory = 0

					insert into @searchWords (searchWord, occurs, scoreBias, isOriginal)
					select distinct listItem, 0, 100, isOriginal from dbo.fn_makeTableFromList_advanced(@cSearchString, ' ')

					delete from @searchWords
						where searchWord in ('and', 'for', 'sale', 'part', 'parts', 'search', 'car', 'to',
							'with', 'system', 'replacement', 'auto', 'antique', 'used', 'roadster', 'cost', 'moss', 'number', 'cars', 'after', 'market', 'inch')
							or (searchWord like '%site:%' or searchWord like '%productSearch%')
							or (len(searchWord) < 2 and not (isnumeric(searchWord) = 1 and len(searchWord) >= 2))
							or (searchWord in (select modelName from dm_models (nolock) where ukey = @nUkeyModel))
							or (searchWord in (select makeName from dm_makes (nolock) where ukey = @nUkeyMake))
							or (searchWord = convert(varchar(20), @nModelYear))
							or searchWord like 'replac%'

					update @searchWords
						set searchWord = left(searchWord, len(searchWord) - 1)
						where right(searchWord, 1) = 's'
							and right(searchWord, 2) <> 'ss'
							and searchWord not in ('gas', 'lens')
							and len(searchWord) > 3

					--if charindex(' ', @cSearchString) > 0
					--	insert into @searchWords (searchWord, occurs, scoreBias, isOriginal) values (replace(@cSearchString, ' ', ''), 0, 50, 0)

					-- synonyms
					insert into @searchWords (searchWord, occurs, scoreBias, isOriginal)
					select distinct [synonym], 0, 100, 1
						from synonyms
						where searchWord = @cSearchString

					insert into @searchWords (searchWord, occurs, scoreBias, isOriginal)
					select distinct b.[synonym], 0, 50, 0
						from @searchWords a
						join synonyms b (nolock) on a.searchWord = b.searchWord
						left outer join @searchWords c on b.synonym = c.searchWord
						where c.searchWord is null

					insert into @searchWords (searchWord, occurs, scoreBias, isOriginal)
					select distinct b.[synonym], 0, 50, 0
						from @searchWords a
						join synonyms b (nolock) on left(a.searchWord, len(a.searchWord) - 1) = b.searchWord
						left outer join @searchWords c on b.synonym = c.searchWord
						where right(a.searchWord, 1) = 's'
							and c.searchWord is null

					update @searchWords
						set modifiedWord = left(searchWord, len(searchWord) - 3)
						where right(searchWord, 3) = 'ing'

					--update @searchWords
					--	set modifiedWord = left(searchWord, len(searchWord) - 2)
					--	where right(searchWord, 2) = 'er'

					update @searchWords
						set occurs = b.numHits
						from @searchWords a
						join lk_websiteWords b (nolock) on a.searchWord = b.word
							and b.ukey_website = @nUkeyWebsite

					update @searchWords
						set occurs = b.numHits
						from @searchWords a
						join lk_websiteWords b (nolock) on left(a.searchWord, len(a.searchWord) - 1) = b.word
							and b.ukey_website = @nUkeyWebsite
						where right(a.searchWord, 1) = 's'
							and isnull(a.occurs, 0) = 0

					update @searchWords
						set occurs = b.numHits
						from @searchWords a
						join lk_websiteWords b (nolock) on b.word like '%' + a.searchWord + '%'
							and b.ukey_website = @nUkeyWebsite
						where len(a.searchWord) >= 3
							and isnull(a.occurs, 0) = 0

					-- here, we're dealing with advanced matching and phrases - so, we have to look at actual descriptions
					update @searchWords
						set occurs = 1
						from @searchWords
						where charindex(' ', searchWord) > 0
							and isnull(occurs, 0) = 0

					update @searchWords set occurs = 0 where occurs is null

					update @searchWords
						set modifiedWord = replace(isnull(modifiedWord, searchWord), '-', '')

					declare @nCounter int
					declare @cSearchWord varchar(500)

					set @nMaxScore = (select sum(occurs) from @searchWords)
					set @nCounter = 3
					while exists (select top 1 searchWord from @searchWords where occurs > 0 and isnull(wordScore, 0) = 0)
					begin
						select top 1
							@cSearchWord = searchWord
							from @searchWords
							where occurs > 0
								and isnull(wordScore, 0) = 0
							order by occurs desc, len(searchWord)

						update @searchWords
							set wordScore = (100 - (100 * (convert(decimal(20,4), occurs) / convert(decimal(20,4), @nMaxScore)))) * (convert(decimal(20,4), scoreBias) / 100.00)
							where searchWord = @cSearchWord

						update @searchWords
							set wordScore = 1
							where searchWord = @cSearchWord
								and wordScore = 0

						set @nCounter = @nCounter + 2
					end

					update @searchWords set wordScore = 1 where searchWord in ('hardware', 'conversion', 'kit')
					update @searchWords set wordScore = 2 where searchWord in ('light', 'dark', 'lights', 'british', 'front', 'rear', 'back')

					if @nUkeyIncomingSearch <> 0
					begin
						insert into @searchTiming (ukey_search, ymd, message)
						select @nUkeyIncomingSearch, getDate(), isnull(searchWord, 'BAD') + ': ' + convert(varchar(20), isnull(wordScore, -1)) + ' / ' + convert(varchar(20), isnull(occurs, -1))
							from @searchWords
					end

					if @nUkeyIncomingSearch <> 0
					begin
						set @cLogMessage = 'Search words scored'
						insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
					end

					--if isnull(@nUkeyCategory, 0) = 0
					--begin
					--	update @searchWords
					--		set categoryScore = 1, wordScore = 10
					--		from @searchWords a
					--		join dm_categories b (nolock) on b.categoryName like '%' + a.searchWord + '%'
					--			and b.ukey_website = @nUkeyWebsite
					--			and b.enabled = 1
					--		join productCategories c (nolock) on b.ukey = c.ukey_category
					--			and c.ukey_website = @nUkeyWebsite
					--		join #matchingProducts d on c.ukey_product = d.ukey_product

					--	if @@rowcount > 0
					--		set @bIncludeCategory = 1

					--	if @nUkeyIncomingSearch <> 0
					--	begin
					--		set @cLogMessage = 'Search words scored based on category name'
					--		insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
					--	end

					--end

					delete from @searchWords where isnull(wordScore, 0) = 0 and isnumeric(searchWord) = 0
				end
			end

			if (isnull(@nUkeyModel, 0) = 0  or @nNumModels = 1)
				and isnull(@nModelYear, 0) = 0
				and (isnull(@nUkeyMake, 0) = 0  or @nNumMakes = 1)
				and @bSearchTerms = 0
				and isnull(@bIsOnSale, 0) = 0
				and isnull(@nUkeyCategory, 0) = 0
				and isnull(@nUkeyDriveLine, 0) = 0
				and isnull(@nUkeyTrimlevel, 0) = 0
				and isnull(@nUkeyModelRange, 0) = 0
			begin
				-- select popular models for the website
				print 'Showing popular models for the website'
				insert into @fitment
				select distinct a.ukey_fitment
					from lk_productApplicationsUsed a (nolock)
					join (
						select top 2 ukey_make, ukey_model
							from lk_popularModels (nolock)
							where ukey_website = @nUkeyWebsite
							order by modelScore desc
						) b on (a.ukey_make = b.ukey_make or a.ukey_make = 0)
						and (a.ukey_model = b.ukey_model or a.ukey_model = 0)
					where a.ukey_website = @nUkeyWebsite

				set @bNoFitmentSupplied = 1
			end
			else
			if (isnull(@nUkeyModel, 0) = 0  or @nNumModels = 1)
				and isnull(@nModelYear, 0) = 0
				and (isnull(@nUkeyMake, 0) = 0  or @nNumMakes = 1)
				and (isnull(@bIsOnSale, 0) = 1 or isnull(@nUkeyCategory, 0) <> 0)
				and isnull(@nUkeyDriveLine, 0) = 0
				and isnull(@nUkeyTrimlevel, 0) = 0
				and isnull(@nUkeyModelRange, 0) = 0
			begin
				-- select sale items
				print 'Showing sale or category items'
				insert into @fitment
				select distinct a.ukey_fitment
					from lk_productApplicationsUsed a (nolock)
					--join (
					--	select top 2 ukey_make, ukey_model
					--		from lk_popularModels (nolock)
					--		where ukey_website = @nUkeyWebsite
					--		order by modelScore desc
					--	) b on (a.ukey_make = b.ukey_make or a.ukey_make = 0)
					--	and (a.ukey_model = b.ukey_model or a.ukey_model = 0)
					where a.ukey_website = @nUkeyWebsite

				set @bNoFitmentSupplied = 1
			end
			else
			if (isnull(@nUkeyModel, 0) = 0  or @nNumModels = 1)
				and isnull(@nModelYear, 0) = 0
				and (isnull(@nUkeyMake, 0) = 0  or @nNumMakes = 1)
				and @bSearchTerms = 0
				and isnull(@bIsOnSale, 0) = 0
				and isnull(@nUkeyCategory, 0) = 0
				and isnull(@bIsOnSale, 0) = 0
				and isnull(@nUkeyModelRange, 0) = 0
			begin
				-- select popular models for this make
				print 'Showing popular models for this make'
				insert into @fitment
				select distinct a.ukey_fitment
					from lk_productApplicationsUsed a (nolock)
					join (
						select top 2 ukey_make, ukey_model
							from lk_popularModels (nolock)
							where ukey_website = @nUkeyWebsite
								and ukey_make = @nUkeyMake
							order by modelScore desc
						) b on (a.ukey_make = b.ukey_make or a.ukey_make = 0)
						and (a.ukey_model = b.ukey_model or a.ukey_model = 0)
					where a.ukey_website = @nUkeyWebsite
			end
			else
			begin
				if (isnull(@nUkeyMake, 0) = 0  or @nNumMakes = 1)
					and (isnull(@nUkeyModel, 0) = 0  or @nNumModels = 1)
					and isnull(@nModelYear, 0) = 0
					and isnull(@nUkeyDriveLine, 0) = 0
					and isnull(@nUkeyTrimlevel, 0) = 0
					and isnull(@nUkeyModelRange, 0) = 0
					and isnull(@nUkeyCategory, 0) = 0
				begin
					print 'no fitment supplied'

					set @bNoFitmentSupplied = 1
				end
				else
				begin
					print 'working with fitment'

					if isnull(@nUkeyModelRange, 0) <> 0
					begin

						-- here, we look at all possible fitments
						insert into @fitment
						select distinct a.ukey
							from dm_fitment a (nolock)
							join (
								select distinct ukey_make, ukey_model, ukey_modelYear, ukey_driveLine, ukey_trimLevel
									from dm_modelRangeFitments a (nolock)
									join dm_fitment b on a.ukey_fitment = b.ukey
									where a.ukey_modelRange = @nUkeyModelRange
								) b on(a.ukey_make = b.ukey_make or a.ukey_make = 0 or b.ukey_make = 0)
								and (a.ukey_model = b.ukey_model or a.ukey_model = 0 or b.ukey_model = 0)
								and (a.ukey_modelYear = b.ukey_modelYear or a.ukey_modelYear = 0 or b.ukey_modelYear = 0)
								and (a.ukey_driveLine = b.ukey_driveLine or a.ukey_driveLine = 0 or b.ukey_driveLine = 0)
								and (a.ukey_trimLevel = b.ukey_trimLevel or a.ukey_trimLevel = 0 or b.ukey_trimLevel = 0)
							where a.ukey_website = @nUkeyWebsite
								and (a.ukey_make = @nUkeyMake or isnull(@nUkeyMake, 0) = 0 or a.ukey_make = 0)
								and (a.ukey_model = @nUkeyModel or isnull(@nUkeyModel, 0) = 0 or a.ukey_model = 0)
								and (a.ukey_trimLevel = @nUkeyTrimLevel or isnull(@nUkeyTrimLevel, 0) = 0 or a.ukey_trimLevel = 0)
								and (a.modelYear = @nModelYear or @nModelYear = 0 or a.modelYear = 0)
								and (a.ukey_driveLine = @nUkeyDriveLine or isnull(@nUkeyDriveLine, 0) = 0 or a.ukey_driveLine = 0)

					end
					else
					begin
						if @nUkeyIncomingSearch <> 0
						begin
							set @cLogMessage = 'Listing all possible fitments'
							insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
						end

						-- here, we look at all possible fitments
						insert into @fitment
						select distinct a.ukey
							from dm_fitment a (nolock)
							where (a.ukey_make = @nUkeyMake or isnull(@nUkeyMake, 0) = 0 or a.ukey_make = 0)
								and (a.ukey_model = @nUkeyModel or isnull(@nUkeyModel, 0) = 0 or a.ukey_model = 0)
								and (a.ukey_trimLevel = @nUkeyTrimLevel or isnull(@nUkeyTrimLevel, 0) = 0 or a.ukey_trimLevel = 0)
								and (a.modelYear = @nModelYear or @nModelYear = 0 or a.modelYear = 0)
								and (a.ukey_driveLine = @nUkeyDriveLine or isnull(@nUkeyDriveLine, 0) = 0 or a.ukey_driveLine = 0)
								and a.ukey_website = @nUkeyWebsite
					end
				end

			end

			set @nRowCount = (select count(*) from @fitment)
			if @nUkeyIncomingSearch <> 0
			begin
				set @cLogMessage = convert(varchar(20), @nRowCount) + ' possible fitments found'
				insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			end

--			create index ix_tmp_fitment_applications on @fitment (ukey_make, ukey_model, ukey_modelYear, ukey_trimLevel, ukey_driveLine) with fillfactor = 100
--			create index ix_tmp_fitment_fitment on @fitment (ukey_fitment) with fillfactor = 100

			if @bSearchTerms = 1
			begin
				if (select count(*) from @searchWords) > 0
				begin
					-- here we want to filter our matched products so that they include only products that mention the search words
					set @cAllSearchWords = ''
					set @cAllSearchWords_and = ''

					select
						@cAllSearchWords = isnull('"*' + searchWord + '*" or ', '') +
							case when isnull(modifiedWord, '') <> isnull(searchWord, '') then isnull('"*' + modifiedWord + '*" or ', '') else '' end + @cAllSearchWords,

						@cAllSearchWords_and = case when isOriginal = 1 then isnull('"*' + searchWord + '*" and ', '') else '' end + @cAllSearchWords_and

						from @searchWords

					if right(@cAllSearchWords, 4) = ' or '
						set @cAllSearchWords = left(@cAllSearchWords, len(@cAllSearchWords) - 3)

					if right(@cAllSearchWords_and, 5) = ' and '
						set @cAllSearchWords_and = left(@cAllSearchWords_and, len(@cAllSearchWords_and) - 4)

					print 'Search String: ' + @cAllSearchWords
					print 'Search String (and): ' + @cAllSearchWords_and

--					create unique index ix_tmpProductsTemp_product on @products_temp (ukey_product) with fillfactor = 90

					if @bNoFitmentSupplied = 1
					begin
						insert into #matchingProducts (ukey_product)
						select ukey_product
							from lk_productSearchStrings (nolock)
							where ukey_website = @nUkeyWebsite
								and contains((searchString, searchString_lowPriority), @cAllSearchWords)

						set @nRowCount = @@rowcount
						if @nUkeyIncomingSearch <> 0
						begin
							set @cLogMessage = convert(varchar(20), @nRowCount) + ' matching products found with ANY search words and no fitment'
							insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
						end
					end
					else
					begin
						-- here, we identify possible fitments
						declare @products_temp table (ukey_product int)

						if isnull(@nUkeyCategory, 0) <> 0
						begin
							insert into @products_temp (ukey_product)
							select a.ukey_product
								from (
									select distinct a.ukey_product
										from productFitment a (nolock)
										join @fitment b on a.ukey_fitment = b.ukey_fitment
										where a.ukey_website = @nUkeyWebsite
									) a
								join (
									select distinct ukey_product
										from productCategories (nolock)
										where ukey_website = @nUkeyWebsite
											and ukey_category in (select ukey_category from dbo.fn_returnChildCategories(@nUkeyWebsite, @nUkeyCategory) a )
									) b on a.ukey_product = b.ukey_product

							set @nRowCount = @@rowcount
							if @nUkeyIncomingSearch <> 0
							begin
								set @cLogMessage = convert(varchar(20), @nRowCount) + ' matching products found with categories'
								insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
							end
						end
						else
						begin
							-- here, we possibly have a very broad search

							if (select count(*) from @fitment) between 1 and 50
							begin
								set @cLogMessage = 'Using regular method'

								insert into @products_temp (ukey_product)
								select distinct a.ukey_product
									from productFitment a (nolock)
									join @fitment b on a.ukey_fitment = b.ukey_fitment
									where a.ukey_website = @nUkeyWebsite
							end
							else
							begin
								-- here, we need to use a real physical table with an index so that the join against productFitment isn't absurdly slow

								-- if we're looking at all possible fitments, skip the productFitment table
								if (select count(*) from @fitment) = (select count(distinct ukey_fitment) from lk_productApplicationsUsed (nolock) where ukey_website = @nUkeyWebsite)
									or @bNoFitmentSupplied = 1
								begin
									set @cLogMessage = 'Selecting from products table'

									insert into @products_temp (ukey_product)
									select distinct a.ukey
										from products a (nolock)
										where ukey_website = @nUkeyWebsite
											and enabled = 1
								end
								else
								begin
									set @cLogMessage = 'Using query without ukey_website'

									insert into @products_temp (ukey_product)
									select distinct a.ukey_product
										from productFitment a (nolock)
										join @fitment b on a.ukey_fitment = b.ukey_fitment

									--create table #fitment_words (ukey_fitment int)
									--create unique index ix_tmp_fitment on #fitment_words (ukey_fitment) with fillfactor = 60
									--insert into #fitment_words (ukey_fitment)
									--select distinct ukey_fitment from @fitment

									--insert into @products_temp (ukey_product)
									--select distinct a.ukey_product
									--	from productFitment a (nolock)
									--	join #fitment_words b on a.ukey_fitment = b.ukey_fitment
									--	where a.ukey_website = @nUkeyWebsite

									--drop table #fitment_words

								end

							end

--							insert into @products_temp (ukey_product)
--							select distinct a.ukey_product
--								from productFitment a (nolock)
--								join @fitment b on a.ukey_fitment = b.ukey_fitment
----								where a.ukey_website = @nUkeyWebsite

							set @nRowCount = (select count(*) from @products_temp)
							if @nUkeyIncomingSearch <> 0
							begin
								set @cLogMessage = convert(varchar(20), @nRowCount) + ' matching products found: ' + isnull(@cLogMessage, 'N/A')
								insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
							end
						end

						if (select count(*) from @products_temp) > 1000
						begin
							insert into #matchingProducts (ukey_product)
							select ukey_product
								from lk_productSearchStrings (nolock)
								where ukey_website = @nUkeyWebsite
									and contains((searchString, searchString_lowPriority), @cAllSearchWords)

							set @nRowCount = @@rowcount
							if @nUkeyIncomingSearch <> 0
							begin
								set @cLogMessage = convert(varchar(20), @nRowCount) + ' matching products based only on search words'
								insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
							end

							delete #matchingProducts
								from #matchingProducts a
								left outer join @products_temp b on a.ukey_product = b.ukey_product
								where b.ukey_product is null

							set @nRowCount = @@rowcount
							if @nUkeyIncomingSearch <> 0
							begin
								set @cLogMessage = convert(varchar(20), @nRowCount) + ' matching products removed that did not fit'
								insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
							end
						end
						else
						begin
							insert into #matchingProducts (ukey_product)
							select a.ukey_product
								from @products_temp a
								join lk_productSearchStrings b (nolock) on a.ukey_product = b.ukey_product
									and b.ukey_website = @nUkeyWebsite
									and contains((searchString, searchString_lowPriority), @cAllSearchWords)

							set @nRowCount = @@rowcount
							if @nUkeyIncomingSearch <> 0
							begin
								set @cLogMessage = convert(varchar(20), @nRowCount) + ' matching products found with search words'
								insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
							end
						end
					end


--					drop table @products_temp
				end
				else
				begin
					-- here, though there were search words we could use none of them and have to return no results
					if @nUkeyIncomingSearch <> 0
					begin
						set @cLogMessage = 'Returning no results, since no search words could be used'
						insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
					end
				end
			end
			else
			begin
				-- here we have no search words to worry about

				set @cLogMessage = ''

				create table #productsThatFit (ukey_product int)

				if (select count(*) from @fitment) between 1 and 50
				begin
					set @cLogMessage = 'Using regular method'

					insert into #productsThatFit
					select distinct a.ukey_product
						from productFitment a (nolock)
						join @fitment b on a.ukey_fitment = b.ukey_fitment
						where a.ukey_website = @nUkeyWebsite
				end
				else
				begin
					-- here, we need to use a real physical table with an index so that the join against productFitment isn't absurdly slow

					-- if we're looking at all possible fitments, skip the productFitment table
					if (select count(*) from @fitment) = (select count(distinct ukey_fitment) from lk_productApplicationsUsed (nolock) where ukey_website = @nUkeyWebsite)
						or @bNoFitmentSupplied = 1
					begin
						set @cLogMessage = 'Selecting from products table'

						insert into #productsThatFit (ukey_product)
						select distinct a.ukey
							from products a (nolock)
							where ukey_website = @nUkeyWebsite
								and enabled = 1
					end
					else
					begin
						set @cLogMessage = 'Using query without ukey_website'

						insert into #productsThatFit
						select distinct a.ukey_product
							from productFitment a (nolock)
							join @fitment b on a.ukey_fitment = b.ukey_fitment

						--create table #fitment (ukey_fitment int)
						--create unique index ix_tmp_fitment on #fitment (ukey_fitment) with fillfactor = 60
						--insert into #fitment (ukey_fitment)
						--select distinct ukey_fitment from @fitment

						--insert into #productsThatFit
						--select distinct a.ukey_product
						--	from productFitment a (nolock)
						--	join #fitment b on a.ukey_fitment = b.ukey_fitment
						--	where a.ukey_website = @nUkeyWebsite

						--drop table #fitment

					end

				end

				set @nRowCount = @@rowcount
				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = convert(varchar(20), @nRowCount) + ' products that fit: ' + isnull(@cLogMessage, 'N/A')
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end

--				create unique index ix_productsThatFit_product on #productsThatFit (ukey_product) with fillfactor = 100

				-- we do, however, have to worry about really generic searches
				if (select count(*) from @fitment) > 10 and isnull(@bIsOnSale, 0) = 0
				begin


					if isnull(@nUkeyCategory, 0) <> 0
					begin
						insert into #matchingProducts (ukey_product)
						select top 250 a.ukey_product
							from (
								select distinct a.ukey_product
									from #productsThatFit a
									join productCategories c (nolock) on a.ukey_product = c.ukey_product
										and c.ukey_website = @nUkeyWebsite
										and c.ukey_category in (select ukey_category from dbo.fn_returnChildCategories(@nUkeyWebsite, @nUkeyCategory) a )
								) a
							left outer join lk_popularProducts d (nolock) on d.ukey_website = @nUkeyWebsite
								and a.ukey_product = d.ukey_product
							join products e (nolock) on a.ukey_product = e.ukey
								and e.ukey_website = @nUkeyWebsite
--								and isnull(e.price, 0) > 0
								and e.enabled = 1
							order by d.productScore desc,
								case when price <> 0 and price < 250 then 1 else 2 end,
								case when price < listPrice then 1 else 2 end,
								case when price > 0 and (listPrice - price) / price > 0.05 then 1 else 2 end desc

						set @nRowCount = @@rowcount
						if @nUkeyIncomingSearch <> 0
						begin
							set @cLogMessage = convert(varchar(20), @nRowCount) + ' generic products found with categories'
							insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
						end

					end
					else
					begin
						insert into #matchingProducts (ukey_product)
						select top 250 a.ukey_product
							from #productsThatFit a
							left outer join lk_popularProducts d (nolock) on d.ukey_website = @nUkeyWebsite
								and a.ukey_product = d.ukey_product
							join products e (nolock) on a.ukey_product = e.ukey
								and e.ukey_website = @nUkeyWebsite
--								and isnull(e.price, 0) > 0
								and e.enabled = 1
							order by d.productScore desc,
								case when price <> 0 and price < 250 then 1 else 2 end,
								case when price < listPrice then 1 else 2 end,
								case when price > 0 and (listPrice - price) / price > 0.05 then 1 else 2 end desc

						set @nRowCount = @@rowcount
						if @nUkeyIncomingSearch <> 0
						begin
							set @cLogMessage = convert(varchar(20), @nRowCount) + ' generic products found'
							insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
						end
					end

					drop table #productsThatFit
				end
				else
				begin
					if isnull(@nUkeyCategory, 0) <> 0
					begin
						insert into #matchingProducts (ukey_product)
						select a.ukey_product
							from #productsThatFit a
							join (
								select distinct ukey_product
									from productCategories (nolock)
									where ukey_website = @nUkeyWebsite
										and ukey_category in (select ukey_category from dbo.fn_returnChildCategories(@nUkeyWebsite, @nUkeyCategory) a )
								) b on a.ukey_product = b.ukey_product

						set @nRowCount = @@rowcount
						if @nUkeyIncomingSearch <> 0
						begin
							set @cLogMessage = convert(varchar(20), @nRowCount) + ' matching products found with categories'
							insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
						end

					end
					else
					begin
						insert into #matchingProducts (ukey_product)
						select ukey_product
							from #productsThatFit

						set @nRowCount = @@rowcount
						if @nUkeyIncomingSearch <> 0
						begin
							set @cLogMessage = convert(varchar(20), @nRowCount) + ' matching products found'
							insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
						end
					end
				end
			end

		end

		create index ix_tmp_matches on #matchingProducts (ukey_product) with fillfactor = 70

		if @nUkeyIncomingSearch <> 0
		begin
			set @cLogMessage = 'Matching products indexed'
			insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
		end

		delete #matchingProducts
			from #matchingProducts a
			join products b (nolock) on a.ukey_product = b.ukey
				and b.ukey_website = @nUkeyWebsite
				and b.enabled = 0

		if @nUkeyIncomingSearch <> 0
		begin
			set @cLogMessage = 'Disabled products removed'
			insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
		end

		if isnull(@bIsOnSale, 0) <> 0
		begin
			delete #matchingProducts
				from #matchingProducts a
				left outer join products b (nolock) on a.ukey_product = b.ukey
					and b.isOnSale = 1
					and b.ukey_website = @nUkeyWebsite
				where b.ukey is null

			set @nRowCount = @@rowcount
			if @nUkeyIncomingSearch <> 0
			begin
				set @cLogMessage = convert(varchar(20), @nRowCount) + ' products deleted based on sale'
				insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			end
		end

--select b.stockCode, b.productDescription
--	from #matchingProducts a
--	join products b on a.ukey_product = b.ukey
--	order by b.stockCode

		if @bSearchTerms = 1
		begin
			set @nNumWords = (select count(*) from @searchWords where isOriginal = 1 and occurs > 0)

			if isnull(@cCategoryName, '') <> ''
				update @searchWords set wordScore = 1 where @cCategoryName like '%' + searchWord + '%' and len(searchWord) >= 3

			-- we're about to rescore based on the search terms
			update #matchingProducts set score = 0

			-- let's try scoring using the fulltext search engine
			declare @cThisWord varchar(1000)
			set @cThisWord = ''

--select * from @searchWords

			while exists (select top 1 @cThisWord from @searchWords where searchWord > @cThisWord)
			begin
				set @cAllSearchWords = ''

				select top 1
					@cAllSearchWords = isnull('"*' + searchWord + '*" or ', '') + case when isnull(modifiedWord, '') <> isnull(searchWord, '') then isnull('"*' + modifiedWord + '*" or ', '') else '' end,
					@cThisWord = searchWord
					from @searchWords
					where searchWord > @cThisWord
					order by searchWord

				if right(@cAllSearchWords, 4) = ' or '
					set @cAllSearchWords = left(@cAllSearchWords, len(@cAllSearchWords) - 3)

				update #matchingProducts
					set score = isnull(a.score, 0) + case
							when searchString like searchWord + ',%'
								or searchString like searchWord + 's,%'
								then isnull(wordScore, 0)*3
							when searchString like searchWord + ' %'
								or searchString like searchWord + 's %'
								then isnull(wordScore, 0)*2
							when searchString like '% ' + searchWord + ' %'
								or searchString like '% ' + searchWord + ',%'
								or searchString like '% ' + searchWord + 's%'
								or searchString like '% ' + searchWord + '.%'
								or searchString like '%(' + searchWord + ')%'
								then isnull(wordScore, 0)*1.5
							when searchString like '%' + searchWord + '%' and (len(searchWord) > 3 or isnumeric(searchWord) = 1)
								then isnull(wordScore, 0)*1.25
							when dbo.fn_removePunctuation(searchString) like '%' + searchWord + '%'  and (len(searchWord) > 3 or isnumeric(searchWord) = 1)
								then isnull(wordScore, 0)*.75
							when dbo.fn_removeEverything(searchString) like '%' + modifiedWord + '%' and (len(modifiedWord) > 3 or isnumeric(modifiedWord) = 1)
								then isnull(wordScore, 0)*.5
							else 0
							end,
						secondaryScore = isnull(a.secondaryScore, 0) + case
							when searchString_lowPriority like '% ' + searchWord + ' %'
								or searchString_lowPriority like '% ' + searchWord + ',%'
								or searchString_lowPriority like '% ' + searchWord + 's%'
								or searchString_lowPriority like '% ' + searchWord + '.%'
								or searchString_lowPriority like '%(' + searchWord + ')%'
								then isnull(wordScore, 0)+4
							when searchString_lowPriority like '%' + searchWord + '%' and (len(searchWord) > 3 or isnumeric(searchWord) = 1)
								then isnull(wordScore, 0)+1
							when dbo.fn_removePunctuation(searchString_lowPriority) like '%' + searchWord + '%'  and (len(searchWord) > 3 or isnumeric(searchWord) = 1)
								then isnull(wordScore, 0)-1
							when dbo.fn_removeEverything(searchString_lowPriority) like '%' + modifiedWord + '%' and (len(modifiedWord) > 3 or isnumeric(modifiedWord) = 1)
								then isnull(wordScore, 0)-2
							else 0
							end,
						wordPosition = case
							when isnull(wordPosition, 0) = 0
								or case
									when charindex(searchWord, searchString) > 0 then charindex(searchWord, searchString)
									when charindex(modifiedWord, searchString) > 0 then charindex(modifiedWord, searchString)
									else null end < isnull(wordPosition, 0)
								then case
									when charindex(searchWord, searchString) > 0 then charindex(searchWord, searchString)
									when charindex(modifiedWord, searchString) > 0 then charindex(modifiedWord, searchString)
									else null end
								else wordPosition
								end,
						numWords = isnull(a.numWords, 0) + case
							when isOriginal = 0 then 0
							when searchString like '%' + searchWord + '%'
								or searchString like '%' + modifiedWord + '%'
							then 1 else 0 end,
						numWords_anywhere = isnull(a.numWords_anywhere, 0) + case
							when isOriginal = 0 then 0
							when searchString_lowPriority like '%' + searchWord + '%'
								or searchString_lowPriority like '%' + modifiedWord + '%'
							then 1 else 0 end,
						containsFullPhrase = case
							when isnull(a.containsFullPhrase, 0) = 1 then 1
							when charindex(@cSearchString, searchString) > 0 then 1
							when charindex(@cSearchString, searchString_lowPriority) > 0 then 1
							when right(@cSearchString, 1) = 'S' and charindex(left(@cSearchString, len(@cSearchString) - 1), searchString) > 0 then 1
							when right(@cSearchString, 1) = 'S' and charindex(left(@cSearchString, len(@cSearchString) - 1), searchString_lowPriority) > 0 then 1
							when replace(searchString, ' ', '') like '%' + replace(@cSearchString, ' ', '') + '%' then 1
							when replace(searchString_lowPriority, ' ', '') like '%' + replace(@cSearchString, ' ', '') + '%' then 1
							else 0
							end
					from #matchingProducts a
					join (
						select ukey_product
							from lk_productSearchStrings (nolock)
							where ukey_website = @nUkeyWebsite
								and contains((searchString, searchString_lowPriority), @cAllSearchWords)
						) b on a.ukey_product = b.ukey_product
					join @searchWords c on c.searchWord = @cThisWord
					join lk_productSearchStrings d (nolock) on a.ukey_product = d.ukey_product
						and d.ukey_website = @nUkeyWebsite

				set @nRowCount = @@rowcount
				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = 'Scores assigned to ' + convert(varchar(20), @nRowCount) + ' matches for ' + @cThisWord
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end
			end

			--update #matchingProducts
			--	set score = b.score,
			--		secondaryScore = b.secondaryScore,
			--		numWords = b.numWords,
			--		numWords_anywhere = b.numWords_anywhere,
			--		wordPosition = isnull(b.wordPosition, 0),
			--		containsFullPhrase = b.containsFullPhrase
			--	from #matchingProducts a
			--	join (
			--		select
			--			a.ukey_product,
			--			sum(case
			--				when searchString like searchWord + ',%'
			--					or searchString like searchWord + 's,%'
			--					then 100 --isnull(wordScore, 0)+6
			--				when searchString like searchWord + ' %'
			--					or searchString like searchWord + 's %'
			--					then 90 --isnull(wordScore, 0)+5
			--				when searchString like '% ' + searchWord + ' %'
			--					or searchString like '% ' + searchWord + ',%'
			--					or searchString like '% ' + searchWord + 's%'
			--					or searchString like '% ' + searchWord + '.%'
			--					or searchString like '%(' + searchWord + ')%'
			--					then isnull(wordScore, 0)+4
			--				when searchString like '%' + searchWord + '%' and (len(searchWord) > 3 or isnumeric(searchWord) = 1)
			--					then isnull(wordScore, 0)+1
			--				--when dbo.fn_removePunctuation(searchString) like '%' + searchWord + '%'  and (len(searchWord) > 3 or isnumeric(searchWord) = 1)
			--				--	then isnull(wordScore, 0)-1
			--				--when dbo.fn_removeEverything(searchString) like '%' + modifiedWord + '%' and (len(modifiedWord) > 3 or isnumeric(modifiedWord) = 1)
			--				--	then isnull(wordScore, 0)-2
			--				else 0
			--				end) as score,

			--			sum(case
			--				when searchString_lowPriority like '% ' + searchWord + ' %'
			--					or searchString_lowPriority like '% ' + searchWord + ',%'
			--					or searchString_lowPriority like '% ' + searchWord + 's%'
			--					or searchString_lowPriority like '% ' + searchWord + '.%'
			--					or searchString_lowPriority like '%(' + searchWord + ')%'
			--					then isnull(wordScore, 0)+4
			--				when searchString_lowPriority like '%' + searchWord + '%' and (len(searchWord) > 3 or isnumeric(searchWord) = 1)
			--					then isnull(wordScore, 0)+1
			--				--when dbo.fn_removePunctuation(searchString_lowPriority) like '%' + searchWord + '%'  and (len(searchWord) > 3 or isnumeric(searchWord) = 1)
			--				--	then isnull(wordScore, 0)-1
			--				--when dbo.fn_removeEverything(searchString_lowPriority) like '%' + modifiedWord + '%' and (len(modifiedWord) > 3 or isnumeric(modifiedWord) = 1)
			--				--	then isnull(wordScore, 0)-2
			--				else 0
			--				end)
			--				as secondaryScore,

			--			count(distinct case
			--				when isOriginal = 0 then null
			--				when searchString like '%' + searchWord + '%' then searchWord
			--				else null end
			--				) as numWords,

			--			count(distinct case
			--				when isOriginal = 0 then null
			--				when searchString_lowPriority like '%' + searchWord + '%' then searchWord
			--				else null end
			--				) as numWords_anywhere,

			--			min(case
			--				when charindex(searchWord, searchString) > 0 then charindex(searchWord, searchString)
			--				when charindex(modifiedWord, searchString) > 0 then charindex(modifiedWord, searchString)
			--				else null end) as wordPosition,

			--			max(case
			--				when charindex(@cSearchString, searchString) > 0 then 1
			--				when right(@cSearchString, 1) = 'S' and charindex(left(@cSearchString, len(@cSearchString) - 1), searchString) > 0 then 1
			--				when replace(searchString, ' ', '') like '%' + replace(@cSearchString, ' ', '') + '%' then 1
			--				else 0
			--				end) as containsFullPhrase

			--			from (
			--					select a.ukey_product,
			--						replace(b.searchString, '-', ' ') as searchString,
			--						replace(b.searchString_lowPriority, '-', ' ') as searchString_lowPriority
			--						from #matchingProducts a
			--						join lk_productSearchStrings b (nolock) on a.ukey_product = b.ukey_product
			--							and b.ukey_website = @nUkeyWebsite
			--					) a, @searchWords b
			--			where searchString like '%' + searchWord + '%'
			--				or searchString_lowPriority like '%' + searchWord + '%'
			--				or searchString like '%' + modifiedWord + '%'
			--				or searchString_lowPriority like '%' + modifiedWord + '%'
			--			group by a.ukey_product
			--		) b on a.ukey_product = b.ukey_product

--select top 500 b.stockCode, b.productDescription, a.*
--	from #matchingProducts a
--	join products b on a.ukey_product = b.ukey
--	order by score desc

	--select * from @searchWords
	--select * from products where stockCode = '11340029571'
	--select * from lk_productSearchStrings where ukey_product = 374599


--			set @nRowCount = @@rowcount
			if @nUkeyIncomingSearch <> 0
			begin
				set @cLogMessage = 'Scores assigned'
				insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			end

			-- remove products that did not score at all
			delete from #matchingProducts where isnull(score, 0) <= 0 and isnull(secondaryScore, 0) <= 0

			set @nRowCount = @@rowcount
			if @nUkeyIncomingSearch <> 0
			begin
				set @cLogMessage = convert(varchar(20), @nRowCount) + ' matches removed with a 0 score'
				insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			end

			-- remove products that did not score the maximum number of words
	--				delete from #matchingProducts where numWords < (select max(numWords) from #matchingProducts)

			--set @nRowCount = @@rowcount
			--if @nUkeyIncomingSearch <> 0
			--begin
			--	set @cLogMessage = convert(varchar(20), @nRowCount) + ' matches removed with a 0 score'
			--	insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			--end

			if @nNumWords > 1
			begin
				print 'Looking for ' +convert(varchar(20), @nNumWords) + ' words'
				update #matchingProducts
					set score = 100
					where (numWords >= @nNumWords)
						and score < 100

				set @nRowCount = @@rowcount
				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = convert(varchar(20), @nRowCount) + ' matches found that use all words'
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end
			end

			if @nNumWords > 1
				and (select count(*) from #matchingProducts where numWords >= @nNumWords) = 0
				and (select count(*) from #matchingProducts where numWords_anywhere >= @nNumWords) > 0
			begin
				delete from #matchingProducts where numWords_anywhere < @nNumWords and score < 75

				set @nRowCount = @@rowcount
				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = convert(varchar(20), @nRowCount) + ' removing matches where words dont appear anywhere'
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end
			end

			if @bPreferenceBasedOnWordPosition = 1
			begin
				-- give preference based on best word position
				update #matchingProducts
					set score = score * 1.25
					where wordPosition between 1 and 5

				set @nRowCount = @@rowcount
				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = convert(varchar(20), @nRowCount) + ' matches found where the word is right up front'
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end
			end

			if @nNumWords > 1
				and charindex(' ', @cSearchString) > 0
			begin
				-- give preference to anything that mentions the full phrase, if there are spaces
				update #matchingProducts
					set score = score * 2
					where containsFullPhrase = 1

				set @nRowCount = @@rowcount
				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = convert(varchar(20), @nRowCount) + ' matches found that contain the full phrase'
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end
			end
		end
		else
		begin

			update #matchingProducts
				set score = b.productScore
				from #matchingProducts a
				join lk_popularProducts b (nolock) on a.ukey_product = b.ukey_product
					and b.ukey_website = @nUkeyWebsite

			update #matchingProducts
				set score = score + 1
				from #matchingProducts a
				join products b (nolock) on a.ukey_product = b.ukey
					and isnull(b.image1url, '') <> ''
					and b.ukey_website = @nUkeyWebsite

			if @nUkeyIncomingSearch <> 0
			begin
				set @cLogMessage = 'Products scored based on popularity'
				insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			end

		end

		update #matchingProducts
			set score = score + isnull(secondaryScore*.75, 0)

--select top 500 b.stockCode, b.productDescription, a.*
--	from #matchingProducts a
--	join products b on a.ukey_product = b.ukey
--	order by score desc

		-- if we searched for a term, find the most likely results
		if @nNumWords > 0
		begin

			if (select count(*) from #matchingProducts where containsFullPhrase = 1) > 5
				and @nNumWords > 1
			begin
				delete from #matchingProducts where containsFullPhrase = 0

				set @nRowCount = @@rowcount
				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = 'Deleted ' + convert(varchar(20), @nRowCount) + ' records records which did not contain the full search phrase.'
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end
			end

			set @nMinScore = (select min(score) from #matchingProducts)
			while (select count(*) from #matchingProducts where score > @nMinScore) >= 5
				and (select count(*) from #matchingProducts) > 25
			begin
				delete from #matchingProducts where score = @nMinScore --and not (numWords = @nNumWords or numWords_anywhere = @nNumWords) --and (containsFullPhrase = 0 or @nNumWords = 1)

				set @nRowCount = @@rowcount
				if @nUkeyIncomingSearch <> 0
				begin
					set @cLogMessage = 'Deleted ' + convert(varchar(20), @nRowCount) + ' records with a score of ' + convert(varchar(20), @nMinScore)
					insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
				end

				if (select count(*) from #matchingProducts where score > @nMinScore) = 0
				begin
					print 'Stopping at score ' + convert(varchar(20), @nMinScore)
					break
				end

				set @nMinScore = (select min(score) from #matchingProducts where score > @nMinScore)

			end



--select * from @searchWords



			if (select count(*) from #matchingProducts) > 5
				and (select count(distinct score) from #matchingProducts) > 2
			begin
				declare @scores table (score int)
				declare @nLastScore int

				insert into @scores
				select distinct score from #matchingProducts

				set @nMinScore = (select min(score) from @scores)
				set @nLastScore = 0
				while exists (select top 1 score from @scores where score > @nLastScore)
				begin
					set @nMinScore = (select top 1 score from @scores where score > @nLastScore order by score)

					if @nLastScore * 2 < @nMinScore and @nLastScore <> 0 and (select count(*) from #matchingProducts) > 10
					begin
						delete from #matchingProducts where score < @nMinScore

						set @nRowCount = @@rowcount
						if @nUkeyIncomingSearch <> 0
						begin
							set @cLogMessage = 'Deleted ' + convert(varchar(20), @nRowCount) + ' records were below the score break of ' + convert(varchar(20), @nMinScore)
							insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
						end

						break
					end
					else
						set @nLastScore = @nMinScore
				end
			end

--select b.stockCode, b.productDescription, a.*
--	from #matchingProducts a
--	join products b on a.ukey_product = b.ukey
--	order by score desc

			--if (select count(*) from #matchingProducts where numWords_anywhere >= @nNumWords) > 0
			--	and @nNumWords > 1
			--	and (select count(*) from #matchingProducts) >= 5
			--begin
			--	delete from #matchingProducts where numWords_anywhere < @nNumWords

			--	set @nRowCount = @@rowcount
			--	if @nUkeyIncomingSearch <> 0
			--	begin
			--		set @cLogMessage = 'Deleted ' + convert(varchar(20), @nRowCount) + ' records that did not use all words'
			--		insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			--	end
			--end

--select b.stockCode, b.productDescription, a.*
--	from #matchingProducts a
--	join products b on a.ukey_product = b.ukey
--	order by score desc

			if @nUkeyIncomingSearch <> 0
			begin
				set @cLogMessage = 'Matches selected based on minimum score'
				insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
			end

		end
	end

	if @bSaveResults = 1
	begin
		insert into cachedSearches (ukey_website, ukey_make, ukey_model, modelYear, ukey_category, searchString, isOnSale, ukey_driveLine, ukey_trimLevel, ukey_modelRange) values (@nUkeyWebsite, @nUkeyMake, @nUkeyModel, @nModelyear, @nUkeyCategory, @cSearchString, @bIsOnSale, @nUkeyDriveLine, @nUkeyTrimLevel, @nUkeyModelRange)
		set @nUkeySearch = scope_identity()

		print 'Cache entry #' + convert(varchar(20), @nUkeySearch) + ' made'

		if @nUkeyIncomingSearch <> 0
		begin
			set @cLogMessage = 'Cache entry #' + convert(varchar(20), @nUkeySearch) + ' made'
			insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
		end

		insert into cachedSearchResults (ukey_website, ukey_search, ukey_product, ukey_application, score)
		select @nUkeyWebsite, @nUkeySearch, ukey_product, ukey_application, score
			from #matchingProducts

		set @cLogMessage = convert(varchar(20), @@rowcount) + ' search results saved to cache'
		print @cLogMessage

		if @nUkeyIncomingSearch <> 0
		begin
			insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
		end

		-- here, we can save the fitments found for use in returning assemblies
		insert into cachedSearchFitments (ukey_website, ukey_search, ukey_fitment)
		select @nUkeyWebsite, @nUkeySearch, ukey_fitment
			from @fitment

		set @cLogMessage = convert(varchar(20), @@rowcount) + ' fitments saved to cache'
		print @cLogMessage

		if @nUkeyIncomingSearch <> 0
		begin
			insert into @searchTiming (ukey_search, ymd, message) values (@nUkeyIncomingSearch, getDate(), @cLogMessage)
		end
	end

	--*************************************************************************************************************
	-- now, output the results

	select ukey_product, ukey_application, score from #matchingProducts

--select b.stockCode, b.productDescription, a.*
--	from #matchingProducts a
--	join products b on a.ukey_product = b.ukey
--	order by score desc

	drop table #matchingProducts

	insert into searchTiming (ukey_search, ymd, message)
	select ukey_search, ymd, message
		from @searchTiming

--	drop table @fitment
end
