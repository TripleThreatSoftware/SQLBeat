select c.*, f.*, g.*
	from products a
	join productFitment b on a.ukey = b.ukey_product
		and a.ukey_website = b.ukey_website
	join dm_fitment c on b.ukey_fitment = c.ukey
		and a.ukey_website = b.ukey_website
		and c.modelYear = 2008
	join dm_makes d on c.ukey_make = d.ukey
		and a.ukey_website = d.ukey_website
		and d.makeName = 'Chevrolet'
	join dm_models e on c.ukey_model = e.ukey
		and a.ukey_website = e.ukey_website
		and e.modelName = 'Silverado'
	join dm_trimLevels f on c.ukey_trimLevel = f.ukey
		and a.ukey_website = f.ukey_website
		and f.trimLevel = '1500 Crew Cab'
	join dm_drivelines g on c.ukey_driveLine = g.ukey
		and a.ukey_website = g.ukey_Website
--		and g.driveLine like '%6 cylinder%'
	where a.stockCode = '12625436'
		and a.ukey_website = 61








drop table #productFitment2
go
drop table #productFitment
go

select distinct a.part_nbr, a.model, a.catalog_code, isnull(a.series_code, '') as series_code, a.first_year, isnull(a.body_style_code, '00') as body_style_code, a.last_year, a.part_usage_lang_id, b.image_name, b.art_nbr, b.illustration_id
	into #productFitment
	from part_usage a
	join callout_legend b on a.part_usage_id = b.part_usage_id
		and a.catalog_code = b.catalog_code
	where a.country_code in ('US', '*')
		and a.part_nbr = '12625436'

go

drop table #productFitment1
go

declare @years table (modelYear int)
declare @nCounter int
set @nCounter = (select MIN(first_year) from #productFitment where FIRST_YEAR is NOT null)

while @nCounter <= 2015
begin
	insert into @years (modelYear) values (@nCounter)
	set @nCounter = @nCounter + 1
end

select a.PART_NBR, a.MODEL, a.CATALOG_CODE, a.series_code, b.modelYear, a.body_style_code, a.PART_USAGE_LANG_ID, a.IMAGE_NAME, a.ART_NBR, a.ILLUSTRATION_ID
	into #productFitment1
	from #productFitment a
	join @years b on a.FIRST_YEAR <= b.modelYear
		and a.LAST_YEAR >= b.modelYear

go


select distinct a.part_nbr, a.model, a.catalog_code, a.series_code, a.modelYear, a.body_style_code, c.engine
	into #productFitment2
	from #productFitment1 a
	left outer join gm_stage.dbo.tmp_optionData c on a.model = c.model
		and a.series_code = c.series_code
		and a.modelYear >= c.first_year
		and a.modelYear <= c.last_year
		and a.catalog_code = c.catalog_code
		and a.image_name = c.image_name
		and a.art_nbr = c.art_nbr
		and a.illustration_id = c.illustration_id

go

drop table #productFitment3
go


select
	distinct
	a.part_nbr as stockCode,
	b.makeName,
	b.modelName,
	a.modelYear,
	b.finalTrimLevel as trimLevel,
	b.optional2 as driveline,
	a.engine

	into #productFitment3
	from #productFitment2 a
	join gm_stage.dbo.allModels_final b on a.model = b.model
		and a.catalog_code = b.catalog_code
		and a.series_code = b.series_code
		and a.modelYear >= b.first_year
		and a.modelYear <= b.last_year
		and (a.body_style_code = b.body_style_code or a.body_style_code = '00' or b.body_style_code = '00')

go

--drop table #modelDrivelines
--go
drop table #productFitment4
go


select distinct a.stockCode, a.makeName, a.modelName, a.modelYear, a.trimLevel, a.driveline, a.engine
	into #productFitment4
	from #productFitment3 a


go


-- add in valid ENGINE field values where the ENGINE field is empty or null
insert into #productFitment4 (stockCode, makeName, modelName, modelYear, driveline, trimLevel, engine)
select
	distinct a.stockCode, a.makeName, a.modelName, a.modelYear, a.driveline, a.trimLevel, b.engine
	from #productFitment4 a
	join (
		select distinct makeName, modelName, modelYear, trimLevel, driveline, ENGINE from #productFitment4 where engine is not null
		) b on a.makeName = b.makeName
		and a.modelName = b.modelName
		and a.modelYear = b.modelYear
		and a.trimLevel = b.trimLevel
		and a.driveline = b.driveline
	where ISNULL(a.engine, '') = ''
		and ISNULL(a.driveline, '') <> ''

-- remove rows where the ENGINE field is null and valid values have been swapped in
delete #productFitment4
	from #productFitment4 a
	join (
		select distinct makeName, modelName, modelYear, trimLevel, driveline, ENGINE from #productFitment4 where engine is not null
		) b on a.makeName = b.makeName
		and a.modelName = b.modelName
		and a.modelYear = b.modelYear
		and a.trimLevel = b.trimLevel
		and a.driveline = b.driveline
	where ISNULL(a.engine, '') = ''
		and ISNULL(a.driveline, '') <> ''

go

select * from assemblyProducts where stockCode = '12625436'

-- this should be v8
select *
	from productFitment
	where modelYear = 2008
		and modelName = 'Silverado'
		and trimLevel = '1500 Crew Cab'
		and stockCode = '12625436'

select *
	from assemblyFitment
	where modelYear = 2008
		and modelName = 'Silverado'
		and trimLevel = '1500 Crew Cab'
		and assemblyKey in ('090810GM00-171GM00-171',
			'051025GM00-266GM00-266',
			'060503TX00-411TX00-411',
			'060320GM00-268GM00-268',
			'060426MW00-058MW00-058')

-- this should be v6
select *
	from productFitment
	where modelYear = 2008
		and modelName = 'Silverado'
		and trimLevel = '1500 Crew Cab'
		and stockCode = '12568989'
