create procedure pr_rpt_databaseFileGrowthHistory (@cServerName varchar(100), @dStartDate dateTime)
as
begin

--	declare @cServerName varchar(100)
--	declare @dStartDate dateTime

--	set @cServerName = 'mssql-ny'
	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))

	create table #sizeHistory (dbName varchar(100), objectName varchar(100), fileName varchar(500), size bigint, isLog bit, ymd dateTime,
		ukey int identity, lastSize bigint)

	insert into #sizeHistory (dbName, objectName, fileName, size, isLog, ymd)
	select dbName, objectName, fileName, size, isLog, ymd
		from databaseFileSizeLog
		where serverName = @cServerName
			and ymd >= @dStartDate
		order by dbName, objectName, ymd

	update a
		set lastSize = b.size
		from #sizeHistory a
		join #sizeHistory b on a.dbName = b.dbName
			and a.objectName = b.objectName
			and a.ukey = b.ukey + 1

	select dbName, objectName, fileName, ymd, lastSize, size as newSize, isLog
		from #sizeHistory
		where size <> lastSize

	drop table #sizeHistory

end

go

grant exec on pr_rpt_databaseFileGrowthHistory to sqlnotification
