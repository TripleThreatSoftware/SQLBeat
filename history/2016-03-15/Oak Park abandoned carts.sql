select a.dateAdded, a.sessionID, a.machineID, a.quantity, a.fitmentString, a.priceSold, b.cartValue, d.stockCode, d.productDescription
	from AppDb_master..cart a (nolock)
	join (
		select a.machineid, a.sessionid, sum(a.priceSold * quantity) as cartValue
			from AppDb_master..cart a (nolock)
			join mart_sessions b (nolock) on a.machineid = b.machineid
				and a.sessionid = b.sessionid
				and b.ukey_website = 19
			where a.dateAdded between '2016-03-10' and '2016-03-15'
			group by a.machineid, a.sessionid
			having sum(a.priceSold * quantity) > 400
		) b on a.machineid = b.machineid
		and a.sessionID = b.sessionID
	left outer join orderheader c on b.machineid = c.machineid
		and b.sessionID = c.sessionID
		and c.confirmedPayment is not null
		and c.cancelled <> 1
		and c.ukey_website = 19
	join products d on a.ukey_product = d.ukey
		and d.ukey_website = 19
	where c.ukey is null
	order by a.machineID, a.sessionID, a.dateAdded
