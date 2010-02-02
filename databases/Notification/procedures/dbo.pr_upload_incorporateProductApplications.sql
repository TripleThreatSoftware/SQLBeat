SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- select * from stage_productApplications where stockCode = '914.423.210.00'
-- select * from dm_makes where ukey_website = 9
-- update stage_productApplications set yearStart = null, yearEnd = null
-- exec pr_upload_incorporateProductApplications 8, 'Replace', 1
-- select * from websites
-- truncate table dm_driveLines

-- update stage_productApplications set modelName = REPLACE(modelName, '/', '-')
-- update stage_productApplications set modelName = REPLACE(modelName, 'C2/4', '911 C2/911 C4')


ALTER procedure [dbo].[pr_upload_incorporateProductApplications] (@nUkeyWebsite int, @cMode varchar(100), @bPreview bit, @bDataCleanup bit = 1)
as
begin

--declare @nUkeyWebsite int
--declare @cMode varchar(100)
--declare @bPreview bit

--set @nUkeyWebsite = 9
--set @cMode = 'Append' -- or Append
--set @bPreview = 1

	set nocount on

	if @bDataCleanup = 1
	begin
		update stage_productApplications set stockCode = replace(stockCode, '"', '') where ukey_website = @nUkeyWebsite
		update stage_productApplications set makeName = replace(makeName, '"', '') where ukey_website = @nUkeyWebsite
		update stage_productApplications set modelName = replace(modelName, '"', '') where ukey_website = @nUkeyWebsite
		update stage_productApplications set modelYears = replace(replace(replace(replace(replace(modelYears, '"', ''), '/2', ''), '.5', ''), '*', ''), '½', '') where ukey_website = @nUkeyWebsite
	--	update stage_productApplications set modelName = replace(modelName, ',', '/') where ukey_website = @nUkeyWebsite
		update stage_productApplications set yearStart = replace(yearStart, '"', '') where ukey_website = @nUkeyWebsite
		update stage_productApplications set yearEnd = replace(yearEnd, '"', '') where ukey_website = @nUkeyWebsite
		update stage_productApplications set driveLine = replace(driveLine, '"', '') where ukey_website = @nUkeyWebsite
		update stage_productApplications set trimLevel = replace(trimLevel, '"', '') where ukey_website = @nUkeyWebsite

		update stage_productApplications set modelName = replace(modelName, '(all versions)', 'ALL') where ukey_website = @nUkeyWebsite
		update stage_productApplications set modelName = replace(modelName, 'Any', 'ALL') where ukey_website = @nUkeyWebsite

		update stage_productApplications set yearStart = LEFT(modelYears, charindex('-', modelYears) - 1) where CHARINDEX('-', modelYears) > 0 and ISNULL(yearStart, '') = ''
		update stage_productApplications set yearEnd = substring(modelYears, charindex('-', modelYears) + 1, 100) where CHARINDEX('-', modelYears) > 0 and ISNULL(yearEnd, '') = ''

		update stage_productApplications set yearStart = '19' + CONVERT(varchar(2), yearStart) where len(yearStart) = 2 and ISNUMERIC(yearStart) = 1 and yearStart > 11
		update stage_productApplications set yearEnd = '19' + CONVERT(varchar(2), yearEnd) where len(yearEnd) = 2 and ISNUMERIC(yearEnd) = 1 and yearEnd > 11
		update stage_productApplications set modelYears = '19' + CONVERT(varchar(2), modelYears) where len(modelYears) = 2 and ISNUMERIC(modelYears) = 1 and modelYears > 11

		delete from stage_productApplications where LEN(yearStart) = 3
		delete from stage_productApplications where LEN(yearEnd) = 3
		delete from stage_productApplications where LEN(yearEnd) = 3
	end

	if @bPreview = 1
		begin transaction preview

	create table #results (ukey int identity, resultString varchar(8000))
	create table #productApplications (ukey int identity, ukey_website int, stockCode varchar(200), makeName varchar(200), modelName varchar(200), modelYear int, driveLine varchar(500), trimLevel varchar(500))


	-- This bit will deal with any stage rows that have a year, including those with no make or model
	declare @nCounter int
	set @nCounter = 1900

	while @nCounter <= 2020
	begin
		insert into #productApplications (ukey_website, stockCode, makeName, modelName, modelYear, driveLine, trimLevel)
		select @nUkeyWebsite, stockCode, makeName, modelName, @nCounter, driveLine, trimLevel
			from stage_productApplications
			where ukey_website = @nUkeyWebsite
				and (
					(modelYears like '%' + convert(varchar(4), @nCounter) + '%' and isnull(modelYears, '') <> '')
					or (
						isnull(yearStart, 0) <> 0 and isnull(yearEnd, 0) <> 0
						and yearStart <= @nCounter
						and yearEnd >= @nCounter
						)
					)

		set @nCounter = @nCounter + 1
	end

	-- this bit will deal with any stage rows that do NOT have a year
	insert into #productApplications (ukey_website, stockCode, makeName, modelName, modelYear, driveLine, trimLevel)
	select @nUkeyWebsite, stockCode, a.makeName, a.modelName, null, a.driveLine, a.trimLevel
		from stage_productApplications a
		--join (
		--	select distinct makeName, modelName, modelYear
		--		from #productApplications
		--	) b on a.makeName = b.makeName
		--		and a.modelName = b.modelName
		where ukey_website = @nUkeyWebsite
			and (
				isnull(a.modelYears, '') in ('', 'All', '0')
				or isnumeric(a.modelYears) = 0
				)
			and isnull(yearStart, 0) = 0
			and isnull(yearEnd, 0) = 0

	--insert into #productApplications (ukey_website, stockCode, makeName, modelName, modelYear, driveLine, trimLevel)
	--select @nUkeyWebsite, stockCode, a.makeName, null, null, a.driveLine, a.trimLevel
	--	from stage_productApplications a
	--	--join (
	--	--	select distinct makeName, modelName, modelYear
	--	--		from #productApplications
	--	--	) b on a.makeName = b.makeName
	--	where ukey_website = @nUkeyWebsite
	--		and isnull(a.modelName, '') in ('', 'All')
	--		and isnull(a.modelYears, '') in ('', 'All')

--	create clustered index ix_tmp_productApplications_ukey_modelName on #productApplications (ukey, modelName) with fillfactor = 70

	--declare @cModelString varchar(8000)

	--set @nCounter = 0
	--while exists (select top 1 ukey from #productApplications where ukey > @nCounter and charindex('/', modelName) > 0)
	--begin
	--	select top 1
	--		@nCounter = ukey,
	--		@cModelString = modelName
	--		from #productApplications
	--		where charindex('/', modelName) > 0
	--			and ukey > @nCounter
	--		order by ukey

	--	insert into #productApplications (ukey_website, stockCode, makeName, modelName, modelYear, driveLine, trimLevel)
	--	select @nUkeyWebsite, stockCode, makeName, b.listItem, modelYear, a.driveLine, a.trimLevel
	--		from #productApplications a, dbo.fn_makeTableFromList(@cModelString, '/') b
	--		where a.ukey = @nCounter

	--	delete from #productApplications where ukey = @nCounter
	--end

	if @cMode = 'Replace'
	begin
		delete dm_makes
			from dm_makes a
			left outer join (
				select distinct makeName
					from #productApplications
					where ukey_website = @nUkeyWebsite
						and makeName is not null
				) b on a.makeName = b.makeName
			where a.ukey_website = @nUkeyWebsite
				and b.makeName is null

		insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' vehicle makes deleted')

		delete dm_models
			from dm_models a
			left outer join dm_makes b (nolock) on a.ukey_make = b.ukey
				and b.ukey_website = @nUkeyWebsite
			left outer join (
				select distinct makeName, modelName
					from #productApplications
					where ukey_website = @nUkeyWebsite
						and makeName is not null
						and modelName is not null
				) c on b.makeName = c.makeName
					and a.modelName = c.modelName
			where a.ukey_website = @nUkeyWebsite
				and c.makeName is null

		insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' vehicle models deleted')

		delete dm_modelYears
			from dm_modelYears a
			left outer join dm_models  (nolock)b on a.ukey_model = b.ukey
				and b.ukey_website = @nUkeyWebsite
			left outer join dm_makes c (nolock) on b.ukey_make = c.ukey
				and c.ukey_website = @nUkeyWebsite
			left outer join #productApplications d on c.makeName = d.makeName
				and b.modelName = d.modelName
				and a.modelYear = d.modelYear
				and d.ukey_website = @nUkeyWebsite
				and d.makeName is not null
				and d.modelName is not null
			where a.ukey_website = @nUkeyWebsite
				and d.makeName is null

		insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' vehicle model years deleted')

		delete dm_driveLines
			from dm_driveLines a
			--left outer join dm_models  (nolock)b on a.ukey_model = b.ukey
			--	and b.ukey_website = @nUkeyWebsite
			left outer join dm_makes c (nolock) on a.ukey_make = c.ukey
				and c.ukey_website = @nUkeyWebsite
			left outer join #productApplications d on c.makeName = d.makeName
--				and b.modelName = d.modelName
				and a.driveLine = d.driveLine
				and d.ukey_website = @nUkeyWebsite
				and d.driveLine is not null
			where a.ukey_website = @nUkeyWebsite
				and d.makeName is null

		insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' vehicle drivelines deleted')

		delete dm_trimLevels
			from dm_trimLevels a
			left outer join dm_models  (nolock)b on a.ukey_model = b.ukey
				and b.ukey_website = @nUkeyWebsite
			left outer join dm_makes c (nolock) on b.ukey_make = c.ukey
				and c.ukey_website = @nUkeyWebsite
			left outer join #productApplications d on c.makeName = d.makeName
				and b.modelName = d.modelName
				and a.trimLevel = d.trimLevel
				and d.ukey_website = @nUkeyWebsite
				and d.trimLevel is not null
			where a.ukey_website = @nUkeyWebsite
				and d.makeName is null

		insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' vehicle trim levels deleted')

	end

	update dm_makes
		set showOnHomePage = 1
		from #productApplications a
		join dm_makes b on a.makeName = b.makeName
			and b.ukey_website = @nUkeyWebsite
		where a.ukey_website = @nUkeyWebsite
			and b.showOnHomePage <> 1

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' vehicle makes enabled')

	insert into dm_makes (ukey_website, makeName, showOnHomePage)
	select distinct @nUkeyWebsite,
		a.makeName, 1
		from #productApplications a
		left outer join dm_makes b (nolock) on a.makeName = b.makeName
			and b.ukey_website = @nUkeyWebsite
		where a.ukey_website = @nUkeyWebsite
			and b.ukey is null
			and isnull(a.makeName, '') <> ''

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' makes added')

	update dm_models
		set enabled = 1
		from #productApplications a
		join dm_makes b (nolock) on a.makeName = b.makeName
			and b.ukey_website = @nUkeyWebsite
		join dm_models c on a.modelName = c.modelName
			and b.ukey = c.ukey_make
			and c.ukey_website = @nUkeyWebsite
		where a.ukey_website = @nUkeyWebsite
			and c.enabled <> 1
			and a.makeName is not null

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' models enabled')

	insert into dm_models (ukey_website, modelName, ukey_make, enabled, featureModel)
	select distinct @nUkeyWebsite,
		a.modelName, b.ukey, 1, 0
		from (
			select distinct makeName, modelName
				from #productApplications
				where ukey_website = @nUkeyWebsite
					and isnull(modelName, '') <> ''
			) a
		join dm_makes b (nolock) on a.makeName = b.makeName
			and b.ukey_website = @nUkeyWebsite
		left outer join dm_models c (nolock) on a.modelName = c.modelName
			and b.ukey = c.ukey_make
			and c.ukey_website = @nUkeyWebsite
		where c.ukey is null

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' models added')

	insert into dm_modelYears (ukey_website, modelYear, ukey_model)
	select distinct @nUkeyWebsite,
		a.modelYear, c.ukey
		from (
			select distinct makeName, modelName, modelYear
				from #productApplications
				where ukey_website = @nUkeyWebsite
					and isnull(modelName, '') <> ''
					and modelYear <> 0
			) a
		join dm_makes b (nolock) on a.makeName = b.makeName
			and b.ukey_website = @nUkeyWebsite
		join dm_models c (nolock) on a.modelName = c.modelName
			and b.ukey = c.ukey_make
			and c.ukey_website = @nUkeyWebsite
		left outer join dm_modelYears d (nolock) on a.modelYear = d.modelYear
			and c.ukey = d.ukey_model
			and d.ukey_website = @nUkeyWebsite
		where d.ukey is null

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' model years added')

	insert into dm_trimLevels (ukey_website, trimLevel, ukey_model, ukey_make)
	select distinct @nUkeyWebsite,
		a.trimLevel, c.ukey, b.ukey
		from (
			select distinct makeName, modelName, trimLevel
				from #productApplications
				where ukey_website = @nUkeyWebsite
					and isnull(modelName, '') <> ''
					and isnull(trimLevel, '') <> ''
			) a
		join dm_makes b (nolock) on a.makeName = b.makeName
			and b.ukey_website = @nUkeyWebsite
		join dm_models c (nolock) on a.modelName = c.modelName
			and b.ukey = c.ukey_make
			and c.ukey_website = @nUkeyWebsite
		left outer join dm_trimLevels d (nolock) on a.trimLevel = d.trimLevel
			and c.ukey = d.ukey_model
			and b.ukey = d.ukey_make
			and d.ukey_website = @nUkeyWebsite
		where d.ukey is null

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' trim levels added')

	insert into dm_driveLines (ukey_website, driveLine, ukey_make) --, ukey_model
	select distinct @nUkeyWebsite,
		a.driveLine, b.ukey --, c.ukey
		from (
			select distinct makeName, driveLine
				from #productApplications
				where ukey_website = @nUkeyWebsite
					and isnull(modelName, '') <> ''
					and isnull(driveLine, '') <> ''
			) a
		join dm_makes b (nolock) on a.makeName = b.makeName
			and b.ukey_website = @nUkeyWebsite
		--join dm_models c (nolock) on a.modelName = c.modelName
		--	and b.ukey = c.ukey_make
		--	and c.ukey_website = @nUkeyWebsite
		left outer join dm_driveLines d (nolock) on a.driveLine = d.driveLine
--			and c.ukey = d.ukey_model
			and b.ukey = d.ukey_make
			and d.ukey_website = @nUkeyWebsite
		where d.ukey is null

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' driveLines added')

	select distinct
		isnull(b.ukey, 0) as ukey_make,
		isnull(c.ukey, 0) as ukey_model,
		isnull(d.ukey, 0) as ukey_modelYear,
		e.ukey as ukey_product,
		isnull(f.ukey, 0) as ukey_driveline,
		isnull(g.ukey, 0) as ukey_trimLevel
		into #allApplications
		from #productApplications a
		join dm_makes b (nolock) on a.makeName = b.makeName
			and b.ukey_website = @nUkeyWebsite
			and a.makeName is not null
		left outer join dm_models c (nolock) on a.modelName = c.modelName
			and b.ukey = c.ukey_make
			and c.ukey_website = @nUkeyWebsite
			and a.modelName is not null
		left outer join dm_modelYears d (nolock) on a.modelYear = d.modelYear
			and c.ukey = d.ukey_model
			and d.ukey_website = @nUkeyWebsite
			and isnull(a.modelYear, 0) <> 0
		join products e (nolock) on a.stockCode = e.stockCode
			and e.ukey_website = @nUkeyWebsite
		left outer join dm_driveLines f (nolock) on a.driveLine = f.driveLine
			and b.ukey = f.ukey_make
--			and c.ukey = f.ukey_model
			and f.ukey_website = @nUkeyWebsite
		left outer join dm_trimLevels g (nolock) on a.trimLevel = g.trimLevel
			and b.ukey = g.ukey_make
			and c.ukey = g.ukey_model
			and g.ukey_website = @nUkeyWebsite
		where a.ukey_website = @nUkeyWebsite

	create index ix_tmp_allApplications on #allApplications (ukey_make, ukey_model, ukey_modelYear, ukey_product, ukey_driveLine, ukey_trimLevel) with fillfactor = 100

--select a.*
--	from #allApplications a
--	left outer join productApplications f (nolock) on f.ukey_website = @nUkeyWebsite
--		and f.ukey_make = a.ukey_make
--		and f.ukey_model = a.ukey_model
--		and f.ukey_modelYear = a.ukey_modelYear
--		and f.ukey_product = a.ukey_product
--	where f.ukey is null

	insert into productApplications (ukey_website, ukey_make, ukey_model, ukey_modelYear, ukey_product, ukey_driveLine, ukey_trimLevel)
	select distinct @nUkeyWebsite,
		a.ukey_make,
		a.ukey_model,
		a.ukey_modelYear,
		a.ukey_product,
		a.ukey_driveLine,
		a.ukey_trimLevel
		from #allApplications a
		left outer join productApplications f (nolock) on f.ukey_website = @nUkeyWebsite
			and a.ukey_make = f.ukey_make
			and a.ukey_model = f.ukey_model
			and a.ukey_modelYear = f.ukey_modelYear
			and a.ukey_driveLine = f.ukey_driveLine
			and a.ukey_trimLevel = f.ukey_trimLevel
			and f.ukey_product = a.ukey_product
		where f.ukey is null

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' product applications added')

	if @cMode = 'Replace'
	begin
		delete productApplications with (rowlock)
			from productApplications a
			left outer join #allApplications f on a.ukey_make = f.ukey_make
				and a.ukey_model = f.ukey_model
				and a.ukey_modelYear = f.ukey_modelYear
				and a.ukey_driveLine = f.ukey_driveLine
				and a.ukey_trimLevel = f.ukey_trimLevel
				and f.ukey_product = a.ukey_product
			where a.ukey_website = @nUkeyWebsite
				and f.ukey_product is null

		insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' product applications deleted')
	end

	drop table #allApplications

	--*********************************************************************************************************************
	--*********************************************************************************************************************
	-- This is all general integrity checking

	update dm_makes
		set showOnHomePage = 0
		from dm_makes a
		left outer join (
			select distinct ukey_make
				from productApplications a (nolock)
				join products b (nolock) on a.ukey_product = b.ukey
					and b.ukey_website = @nUkeyWebsite
					and b.enabled = 1
				where a.ukey_website = @nUkeyWebsite
			) b on a.ukey = b.ukey_make
		where b.ukey_make is null
			and a.showOnHomePage = 1
			and a.ukey_website = @nUkeyWebsite

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' unused vehicle makes disabled')

	update dm_models
		set enabled = 0
		from dm_models a
		left outer join (
			select distinct ukey_make, ukey_model
				from productApplications a (nolock)
				join products b (nolock) on a.ukey_product = b.ukey
					and b.ukey_website = @nUkeyWebsite
					and b.enabled = 1
				where a.ukey_website = @nUkeyWebsite
			) b on a.ukey = b.ukey_model
				and a.ukey_make = b.ukey_make
		where b.ukey_model is null
			and a.enabled = 1
			and a.ukey_website = @nUkeyWebsite

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' unused vehicle models disabled')

	delete productApplications with (rowlock)
		from productApplications a
		left outer join dm_makes b (nolock) on a.ukey_make = b.ukey
			and b.ukey_website = @nUkeyWebsite
		where b.ukey is null
			and a.ukey_website = @nUkeyWebsite
			and a.ukey_make <> 0

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' applications for deleted/inactive makes dropped')

	delete productApplications with (rowlock)
		from productApplications a
		left outer join dm_models b (nolock) on a.ukey_model = b.ukey
			and b.ukey_website = @nUkeyWebsite
			and a.ukey_make = b.ukey_make
		where b.ukey is null
			and a.ukey_website = @nUkeyWebsite
			and a.ukey_model <> 0

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' applications for deleted/inactive model years dropped')

	delete productApplications with (rowlock)
		from productApplications a
		left outer join dm_modelYears b (nolock) on a.ukey_modelYear = b.ukey
			and b.ukey_website = @nUkeyWebsite
			and a.ukey_model = b.ukey_model
		where b.ukey is null
			and a.ukey_website = @nUkeyWebsite
			and a.ukey_modelYear <> 0

	insert into #results (resultString) values (convert(varchar(20), @@rowcount) + ' applications for deleted/inactive model years dropped')

	select * from #results

	drop table #productApplications
	drop table #results

	if @bPreview = 1
		rollback
	else
	begin
		update statistics productApplications
		exec pr_maintainProductApplicationsUsed
	end
end
