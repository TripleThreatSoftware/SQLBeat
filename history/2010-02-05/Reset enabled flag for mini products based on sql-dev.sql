update a
	set enabled = 1
--select a.stockCode, a.productDescription, a.price, a.enabled, b.price, b.enabled
	from products a (nolock)
	join [sql-dev].AppDb.dbo.products b on a.stockCode = b.stockCode
		and b.ukey_website = 7
	where a.ukey_website = 7
		and a.enabled = 0
		and b.enabled = 1
exec pr_maintainProductApplicationsUsed

select *
	from productApplications a
	join products b on a.ukey_product = b.ukey
		and b.stockCode = '51452755010'
		and b.ukey_website = 7
	where a.ukey_Website = 7

select url,posttoweb, * from atrexMirror..code where stockCode = '51452755010'
select * from products where stockCode = '51452755010'
