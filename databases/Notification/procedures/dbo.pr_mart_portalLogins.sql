create procedure pr_mart_portalLogins
as
begin

	SELECT
		dateAdd(hour, datePart(hour, createdDate), convert(varchar(10), createdDate, 120)) as ymd,
		COUNT(*) AS numLogins
		into #portalLogins
		FROM sqlcluster01.portalpro.dbo.SessionLog
		WHERE (SessionID IS NOT NULL)
		GROUP BY convert(varchar(10), createdDate, 120),
			datePart(hour, createdDate)

	delete mart_portalLogins_byHour
		from mart_portalLogins_byHour a
		join #portalLogins b on a.ymd = b.ymd

	insert into mart_portalLogins_byHour (ymd, numLogins)
	select ymd, numLogins
		from #portalLogins

	drop table #portalLogins
end


select * from mart_portalLogins_byHour
GO
