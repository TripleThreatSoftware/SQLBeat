declare @nUkeyClient int
set @nUkeyClient = 3


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

	insert into @results (resultString) values ('Product options removed')

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

	insert into @results (resultString) values ('Option values added')

	select a.*
		into #missingOptions
		from productOptions a (nolock)
		left outer join AppDb.dbo.productOptions b (nolock) on a.ukey = b.ukey_inventory
		where a.ukey_client = @nUkeyClient
			and b.ukey is null

	insert into AppDb.dbo.productOptions (ukey_website, ukey_option, ukey_optionValue, ukey_product, ukey_inventory)
	select c.ukey_website, c.ukey, d.ukey, e.ukey, a.ukey
		from #missingOptions a
		join dm_options b (nolock) on a.ukey_option = b.ukey
		join AppDb.dbo.dm_options c (nolock) on b.ukey = c.ukey_inventory
		join AppDb.dbo.dm_optionValues d (nolock) on c.ukey = d.ukey_option
			and isnull(a.optionValue, '') = isnull(d.optionValue, '')
			and c.ukey_website = d.ukey_website
		join AppDb.dbo.products e (nolock) on a.ukey_product = e.ukey_inventory


	drop table #missingOptions
	drop table #allClientOptions
	drop table #productOptionKeys
