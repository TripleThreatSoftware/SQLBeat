USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_graph_sqlCPULoad_byDatabase_byHour]    Script Date: 02/17/2010 11:33:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_graph_sqlDiskLoad_byDatabase_byHour 'sqlcluster01'

ALTER procedure [dbo].[pr_graph_sqlDiskLoad_byDatabase_byHour] (@cServerName varchar(100))
as
begin

--	declare @cServerName varchar(100)
--	set @cServerName = 'mssql-ny'

	declare @dStartDate dateTime
	set @dStartDate = dateAdd(hour, -48, getDate())

	set nocount on

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		dbName as setName,
		'DiskIO' as seriesName,
		convert(varchar(2),
			case
				when ymd_hour >= 13
					then ymd_hour - 12
					else ymd_hour
					end) +
			case
				when ymd_hour >= 13
				then 'p'
				else 'a'
			end
			as axis_x,
		diskIO as axis_y

		from mart_database_byHour (nolock)
		where serverName = @cServerName
			and dateAdd(hour, ymd_hour, ymd)  >= @dStartDate
			and dbName in (select top 5 dbName from mart_database_byHour (nolock) where serverName = @cServerName and dateAdd(hour, ymd_hour, ymd) >= @dStartDate group by dbName order by sum(diskIO) desc)
		order by dbName, ymd, ymd_hour


	exec pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0

	drop table #dataValues

end
