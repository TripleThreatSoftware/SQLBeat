GO
ALTER procedure [dbo].[pr_maintainProductApplicationStrings]
as
begin

	declare @nThisUkey int
	declare @nUkeyWebsite int
	declare @cApplication varchar(500)
	declare @bShowDrivelineInApplicationString bit

	set nocount on

	set @nThisUkey = 0
	create table #results (ukey_website int, ukey_product int, applicationString varchar(8000))
	declare @productApplications table (makeName varchar(500), modelName varchar(500), minYear varchar(4), maxYear varchar(4), driveLine varchar(200), trimLevel varchar(200))

	while exists (select top 1 ukey from products (nolock) where ukey > @nThisUkey and enabled = 1)
	begin
		select top 1
			@nThisUkey = ukey,
			@nUkeyWebsite = ukey_website
			from products (nolock)
			where ukey > @nThisUkey
				and enabled = 1
			order by ukey

		set @bShowDrivelineInApplicationString = (select top 1 showDrivelineInApplicationString from websites (nolock) where ukey = @nUkeyWebsite)

		delete from @productApplications
		set @cApplication = ''

		if @bShowDrivelineInApplicationString = 1
		begin
			insert into @productApplications (makeName, modelName, minYear, maxYear, driveLine, trimlevel)
			select
				e.makeName,
				d.modelName,
				min(c.modelYear) as minYear,
				max(c.modelYear) as maxYear,
				f.driveLine,
				g.trimlevel
				from productApplications b (nolock)
				left outer join dm_modelYears c (nolock) on b.ukey_modelYear = c.ukey
					and b.ukey_model = c.ukey_model
					and c.ukey_website = @nUkeyWebsite
				left outer join dm_models d (nolock) on b.ukey_model = d.ukey
					and d.ukey_website = @nUkeyWebsite
					and d.ukey_make = b.ukey_make
				left outer join dm_makes e (nolock) on b.ukey_make = e.ukey
					and d.ukey_make = e.ukey
					and e.ukey_website = @nUkeyWebsite
				left outer join dm_driveLines f (nolock) on b.ukey_driveLine = f.ukey
					and  f.ukey_website = @nUkeyWebsite
				left outer join dm_trimLevels g (nolock) on b.ukey_trimLevel = g.ukey
					and g.ukey_website = @nUkeyWebsite
				where b.ukey_product = @nThisUkey
					and b.ukey_website = @nUkeyWebsite
				group by
					e.makeName,
					d.modelName,
					f.driveLine,
					g.trimlevel
		end
		else
		begin
			insert into @productApplications (makeName, modelName, minYear, maxYear, trimlevel)
			select
				e.makeName,
				d.modelName,
				min(c.modelYear) as minYear,
				max(c.modelYear) as maxYear,
				g.trimlevel
				from productApplications b (nolock)
				left outer join dm_modelYears c (nolock) on b.ukey_modelYear = c.ukey
					and b.ukey_model = c.ukey_model
					and c.ukey_website = @nUkeyWebsite
				left outer join dm_models d (nolock) on b.ukey_model = d.ukey
					and d.ukey_website = @nUkeyWebsite
					and d.ukey_make = b.ukey_make
				left outer join dm_makes e (nolock) on b.ukey_make = e.ukey
					and d.ukey_make = e.ukey
					and e.ukey_website = @nUkeyWebsite
				left outer join dm_trimLevels g (nolock) on b.ukey_trimLevel = g.ukey
					and g.ukey_website = @nUkeyWebsite
				where b.ukey_product = @nThisUkey
					and b.ukey_website = @nUkeyWebsite
				group by
					e.makeName,
					d.modelName,
					g.trimlevel
		end

		if @@rowcount > 6
		begin

			select @cApplication = @cApplication +
					isnull(makeName, 'All Makes') +
					case
						when min(minYear) is null and max(maxYear) is null then ' (All Years)'
						when min(minYear) <> max(maxYear) then ' (' + convert(varchar(4), min(minYear)) + '-' + convert(varchar(4), max(maxYear)) + ')'
						else ' (' + convert(varchar(4), min(minYear)) + ')'
						end + ', '
				from @productApplications
				group by makeName
				order by makeName

		end
		else
		begin

			select @cApplication = @cApplication +
				isnull(modelName, 'All Models') +
					case when isnull(trimlevel, '') <> '' then ' ' + trimlevel else '' end +
					case when isnull(driveLine, '') <> '' then ' (' + driveLine + ') ' else '' end +
					case
						when minYear is null and maxYear is null then ' (All Years)'
						when minYear <> maxYear then ' (' + convert(varchar(4), minYear) + '-' + convert(varchar(4), maxYear) + ')'
						else ' (' + convert(varchar(4), minYear) + ')'
						end + ', '
				from @productApplications
				order by modelName, trimlevel

		end

		if right(@cApplication, 2) = ', '
			set @cApplication = left(@cApplication, len(@cApplication) -1)

		insert into #results (ukey_website, ukey_product, applicationString) values (@nUkeyWebsite, @nThisUkey, @cApplication)
	end

	select *
		into lk_productApplicationStrings_new
		from #results

	create clustered index ix_productApplicationStrings_website_product_applicationString on lk_productApplicationStrings_new (ukey_website, ukey_product, applicationString) with fillfactor = 100

	begin transaction swapApplicationString

	exec sp_rename 'lk_productApplicationStrings', 'lk_productApplicationStrings_old'
	exec sp_rename 'lk_productApplicationStrings_new', 'lk_productApplicationStrings'

	commit transaction swapApplicationString

	drop table lk_productApplicationStrings_old

	drop table #results
end

-- select top 1000 * from lk_productApplicationStrings
