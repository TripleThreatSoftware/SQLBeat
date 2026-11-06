/****** Object:  View [dbo].[v_fact_weblogs_all]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_fact_weblogs_all] as
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202611..fact_weblogs_20261106 where ymd >= '2026-11-06 00:00:00' and ymd < '2026-11-07' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202611..fact_weblogs_20261105 where ymd >= '2026-11-05 00:00:00' and ymd < '2026-11-06' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202611..fact_weblogs_20261104 where ymd >= '2026-11-04 00:00:00' and ymd < '2026-11-05' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202611..fact_weblogs_20261103 where ymd >= '2026-11-03 00:00:00' and ymd < '2026-11-04' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202611..fact_weblogs_20261102 where ymd >= '2026-11-02 00:00:00' and ymd < '2026-11-03' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202611..fact_weblogs_20261101 where ymd >= '2026-11-01 00:00:00' and ymd < '2026-11-02' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_20261031 where ymd >= '2026-10-31 00:00:00' and ymd < '2026-11-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_20261030 where ymd >= '2026-10-30 00:00:00' and ymd < '2026-10-31' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_20261029 where ymd >= '2026-10-29 00:00:00' and ymd < '2026-10-30' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_20261028 where ymd >= '2026-10-28 00:00:00' and ymd < '2026-10-29' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_20261027 where ymd >= '2026-10-27 00:00:00' and ymd < '2026-10-28' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_20261026 where ymd >= '2026-10-26 00:00:00' and ymd < '2026-10-27' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_20261025 where ymd >= '2026-10-25 00:00:00' and ymd < '2026-10-26' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_202610_week43 where ymd >= '2026-10-18 00:00:00' and ymd < '2026-10-25' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_202610_week42 where ymd >= '2026-10-11 00:00:00' and ymd < '2026-10-18' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_202610_week41 where ymd >= '2026-10-04 00:00:00' and ymd < '2026-10-11' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202610..fact_weblogs_202610_week40 where ymd >= '2026-10-01 00:00:00' and ymd < '2026-10-04' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202609..fact_weblogs_202609_week40 where ymd >= '2026-09-27 00:00:00' and ymd < '2026-10-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202609..fact_weblogs_202609_week39 where ymd >= '2026-09-20 00:00:00' and ymd < '2026-09-27' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202609..fact_weblogs_202609_week38 where ymd >= '2026-09-13 00:00:00' and ymd < '2026-09-20' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202609..fact_weblogs_202609_week37 where ymd >= '2026-09-06 00:00:00' and ymd < '2026-09-13' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202609..fact_weblogs_202609_week36 where ymd >= '2026-09-01 00:00:00' and ymd < '2026-09-06' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202608..fact_weblogs_202608_week36 where ymd >= '2026-08-30 00:00:00' and ymd < '2026-09-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202608..fact_weblogs_202608_week35 where ymd >= '2026-08-23 00:00:00' and ymd < '2026-08-30' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202608..fact_weblogs_202608_week34 where ymd >= '2026-08-16 00:00:00' and ymd < '2026-08-23' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202608..fact_weblogs_202608_week33 where ymd >= '2026-08-09 00:00:00' and ymd < '2026-08-16' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202608..fact_weblogs_202608_week32 where ymd >= '2026-08-02 00:00:00' and ymd < '2026-08-09' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202608..fact_weblogs_202608_week31 where ymd >= '2026-08-01 00:00:00' and ymd < '2026-08-02' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202607..fact_weblogs_202607_week31 where ymd >= '2026-07-26 00:00:00' and ymd < '2026-08-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202607..fact_weblogs_202607_week30 where ymd >= '2026-07-19 00:00:00' and ymd < '2026-07-26' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202607..fact_weblogs_202607_week29 where ymd >= '2026-07-12 00:00:00' and ymd < '2026-07-19' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202607..fact_weblogs_202607_week28 where ymd >= '2026-07-05 00:00:00' and ymd < '2026-07-12' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202607..fact_weblogs_202607_week27 where ymd >= '2026-07-01 00:00:00' and ymd < '2026-07-05' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202606..fact_weblogs_202606_week27 where ymd >= '2026-06-28 00:00:00' and ymd < '2026-07-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202606..fact_weblogs_202606_week26 where ymd >= '2026-06-21 00:00:00' and ymd < '2026-06-28' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202606..fact_weblogs_202606_week25 where ymd >= '2026-06-14 00:00:00' and ymd < '2026-06-21' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202606..fact_weblogs_202606_week24 where ymd >= '2026-06-07 00:00:00' and ymd < '2026-06-14' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202606..fact_weblogs_202606_week23 where ymd >= '2026-06-01 00:00:00' and ymd < '2026-06-07' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202605..fact_weblogs_202605_week23 where ymd >= '2026-05-31 00:00:00' and ymd < '2026-06-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202605..fact_weblogs_202605_week22 where ymd >= '2026-05-24 00:00:00' and ymd < '2026-05-31' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202605..fact_weblogs_202605_week21 where ymd >= '2026-05-17 00:00:00' and ymd < '2026-05-24' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202605..fact_weblogs_202605_week20 where ymd >= '2026-05-10 00:00:00' and ymd < '2026-05-17' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202605..fact_weblogs_202605_week19 where ymd >= '2026-05-03 00:00:00' and ymd < '2026-05-10' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202605..fact_weblogs_202605_week18 where ymd >= '2026-05-01 00:00:00' and ymd < '2026-05-03' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202604..fact_weblogs_202604_week18 where ymd >= '2026-04-26 00:00:00' and ymd < '2026-05-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202604..fact_weblogs_202604_week17 where ymd >= '2026-04-19 00:00:00' and ymd < '2026-04-26' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202604..fact_weblogs_202604_week16 where ymd >= '2026-04-12 00:00:00' and ymd < '2026-04-19' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202604..fact_weblogs_202604_week15 where ymd >= '2026-04-05 00:00:00' and ymd < '2026-04-12' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202604..fact_weblogs_202604_week14 where ymd >= '2026-04-01 00:00:00' and ymd < '2026-04-05' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202603..fact_weblogs_202603_week14 where ymd >= '2026-03-29 00:00:00' and ymd < '2026-04-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202603..fact_weblogs_202603_week13 where ymd >= '2026-03-22 00:00:00' and ymd < '2026-03-29' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202603..fact_weblogs_202603_week12 where ymd >= '2026-03-15 00:00:00' and ymd < '2026-03-22' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202603..fact_weblogs_202603_week11 where ymd >= '2026-03-08 00:00:00' and ymd < '2026-03-15' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202603..fact_weblogs_202603_week10 where ymd >= '2026-03-01 00:00:00' and ymd < '2026-03-08' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202602..fact_weblogs_202602_week9 where ymd >= '2026-02-22 00:00:00' and ymd < '2026-03-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202602..fact_weblogs_202602_week8 where ymd >= '2026-02-15 00:00:00' and ymd < '2026-02-22' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202602..fact_weblogs_202602_week7 where ymd >= '2026-02-08 00:00:00' and ymd < '2026-02-15' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202602..fact_weblogs_202602_week6 where ymd >= '2026-02-01 00:00:00' and ymd < '2026-02-08' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202601..fact_weblogs_202601_week5 where ymd >= '2026-01-25 00:00:00' and ymd < '2026-02-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202601..fact_weblogs_202601_week4 where ymd >= '2026-01-18 00:00:00' and ymd < '2026-01-25' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202601..fact_weblogs_202601_week3 where ymd >= '2026-01-11 00:00:00' and ymd < '2026-01-18' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202601..fact_weblogs_202601_week2 where ymd >= '2026-01-04 00:00:00' and ymd < '2026-01-11' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202601..fact_weblogs_202601_week1 where ymd >= '2026-01-01 00:00:00' and ymd < '2026-01-04' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202512..fact_weblogs_202512_week53 where ymd >= '2025-12-28 00:00:00' and ymd < '2026-01-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202512..fact_weblogs_202512_week52 where ymd >= '2025-12-21 00:00:00' and ymd < '2025-12-28' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202512..fact_weblogs_202512_week51 where ymd >= '2025-12-14 00:00:00' and ymd < '2025-12-21' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202512..fact_weblogs_202512_week50 where ymd >= '2025-12-07 00:00:00' and ymd < '2025-12-14' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202512..fact_weblogs_202512_week49 where ymd >= '2025-12-01 00:00:00' and ymd < '2025-12-07' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202511..fact_weblogs_202511_week49 where ymd >= '2025-11-30 00:00:00' and ymd < '2025-12-01' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202511..fact_weblogs_202511_week48 where ymd >= '2025-11-23 00:00:00' and ymd < '2025-11-30' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202511..fact_weblogs_202511_week47 where ymd >= '2025-11-16 00:00:00' and ymd < '2025-11-23' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202511..fact_weblogs_202511_week46 where ymd >= '2025-11-09 00:00:00' and ymd < '2025-11-16' union all
	select timeTaken,ukey,ukey_clientIP,ukey_method,ukey_site,ukey_sourceFile,ukey_sourceIP,ukey_uriStem,ukey_userAgent,win32Status,xForwardedFor,ymd,appSessionID,bytes,clientIPRaw,cookie,hostname,queryString,referer,requestStatus,requestSubStatus,sessionID,siteName
	from Weblogs202511..fact_weblogs_202511_week45 where ymd >= '2025-11-02 00:00:00' and ymd < '2025-11-09'
GO
