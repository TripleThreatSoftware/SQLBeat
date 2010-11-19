delete
	from websiteModels
	where ukey_model in (select ukey from dm_models where ukey_client = 9 and modelName not in ('240', '850', '960', 'C30', 'C70' ,'S40', 'S60', 'S70', 'S80', 'S90', 'V40', 'V50', 'V70', 'V70 XC', 'XC60', 'XC70', 'XC90'))
		and ukey_client = 9

update AppDb.dbo.dm_models
	set Enabled = 0
	where ukey in (select ukey from AppDb.dbo.dm_models  where ukey_website = 19 and modelName not in ('240', '850', '960', 'C30', 'C70' ,'S40', 'S60', 'S70', 'S80', 'S90', 'V40', 'V50', 'V70', 'V70 XC', 'XC60', 'XC70', 'XC90'))
		and ukey_website = 19

update products
	set isPerformance = b.isPerformance, isAccessory = b.isAccessory
	from products a
	join AppDb.dbo.products b on a.ukey = b.ukey_inventory
		and b.ukey_website = 19
	where a.ukey_client = 9
