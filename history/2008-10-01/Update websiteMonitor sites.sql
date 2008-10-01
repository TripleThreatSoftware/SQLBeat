select *
	from monitoredURLs
	order by websiteURL

--update monitoredURLs set websiteURL = 'http:///alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'UATMSWEB01.Public'
update monitoredURLs set websiteURL = 'http://172.24.45.152/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'UATMSWEB03.Portal'
update monitoredURLs set websiteURL = 'http://172.24.45.180/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'UATMSWEB02.Portal'
update monitoredURLs set websiteURL = 'http://172.24.45.185/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'UATMSWEB02.Public'
update monitoredURLs set websiteURL = 'http://172.24.45.156/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'UATMSWEB03.Public'
--update monitoredURLs set websiteURL = 'http:///alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'UATMSWEB01.Portal'
update monitoredURLs set websiteURL = 'http://172.27.45.11/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB04.Public'
update monitoredURLs set websiteURL = 'http://172.27.45.12/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB04.Portal'
update monitoredURLs set websiteURL = 'http://172.27.45.131/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB02.Portal'
--update monitoredURLs set websiteURL = 'http:///alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB07.Portal'
--update monitoredURLs set websiteURL = 'http:///alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB07.Public'
update monitoredURLs set websiteURL = 'http://172.27.45.133/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB02.Public'
--update monitoredURLs set websiteURL = 'http:///alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB06.Public'
update monitoredURLs set websiteURL = 'http://172.27.45.192/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB05.Public'
update monitoredURLs set websiteURL = 'http://172.27.45.196/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB05.Portal'
--update monitoredURLs set websiteURL = 'http:///alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB06.Portal'
update monitoredURLs set websiteURL = 'http://172.27.45.36/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB01.Public'
update monitoredURLs set websiteURL = 'http://172.27.45.38/alteonHealthCheck.htm', isEnabled = 1 where friendlyName = 'appWEB01.Portal'

insert into monitoredURLs (websiteURL, isEnabled, friendlyName, matchString) values (
	'http://172.27.45.233/alteonHealthCheck.htm', 1, 'appWEB03.Public', 'All is well')
insert into monitoredURLs (websiteURL, isEnabled, friendlyName, matchString) values (
	'http://172.27.45.235/alteonHealthCheck.htm', 1, 'appWEB03.Portal', 'All is well')

delete from monitoredURLs where friendlyName like '%appweb06%' or friendlyName like '%appweb07%' or friendlyName like '%uatmsweb01%'
