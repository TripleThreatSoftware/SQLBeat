select *
	into productOptions_20101019
	from web03.AppDb_inventory.dbo.productOptions

insert into web03.AppDb_inventory.dbo.productOptions (ymd, ukey_client, ukey_product, ukey_option, optionValue, optionPrice, optionListPrice)
select a.ymd, a.ukey_client, a.ukey_product, a.ukey_option, a.optionValue, a.optionPrice, a.optionListPrice
	from productOptions a
	left outer join productOptions_20101019 b on a.ukey = b.ukey
	where b.ukey is null
