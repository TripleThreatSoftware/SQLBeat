create table mart_site_page_byday (ukey int identity, websiteURL varchar(500), numActiveMinutes int, bytesDelivered bigint, pageURL varchar(5000), ymd dateTime, numRequests int,
	getTime int, postTime int, getsOver5s int, getsOver25s int, num4xx int, num5xx int)
GO
