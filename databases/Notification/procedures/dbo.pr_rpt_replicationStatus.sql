ALTER procedure [dbo].[pr_rpt_replicationStatus]
as
begin

	select a.*,
		case when numRecords_publisher <> numRecords_subscriber
			then '<div class="gridAlert_bad">Missing ' + convert(varchar(20), abs(numRecords_subscriber - numRecords_publisher)) + ' records</div>'
			else ''
			end as numRecords_warning

		from (
			select
				convert(varchar(10), maxDate, 120) as ymd,
				'mssql-slv2' as subscriberName,
				databaseName, tableName,

				max(case when serverName = 'mssql-ny' then numRecords else 0 end) as numRecords_publisher,
				max(case when serverName = 'mssql-ny' then maxDate else null end) as maxDate_publisher,

				max(case when serverName = 'mssql-slv2' then numRecords else 0 end) as numRecords_subscriber,
				max(case when serverName = 'mssql-slv2' then maxDate else null end) as maxDate_subscriber

				from mart_replicationStatus
				where maxDate >= dateAdd(day, -7, getDate())
				group by convert(varchar(10), maxDate, 120), databaseName, tableName
			) a
	union
	select a.*,
		case when numRecords_publisher <> numRecords_subscriber
			then '<div class="gridAlert_bad">Missing ' + convert(varchar(20), abs(numRecords_subscriber - numRecords_publisher)) + ' records</div>'
			else ''
			end as numRecords_warning

		from (
			select
				convert(varchar(10), maxDate, 120) as ymd,
				'mssqla-ny' as subscriberName,
				databaseName, tableName,

				max(case when serverName = 'mssql-ny' then numRecords else 0 end) as numRecords_publisher,
				max(case when serverName = 'mssql-ny' then maxDate else null end) as maxDate_publisher,

				max(case when serverName = 'mssqla-ny' then numRecords else 0 end) as numRecords_subscriber,
				max(case when serverName = 'mssqla-ny' then maxDate else null end) as maxDate_subscriber

				from mart_replicationStatus
				where maxDate >= dateAdd(day, -7, getDate())
				group by convert(varchar(10), maxDate, 120), databaseName, tableName
			) a
		order by subscriberName, databaseName, tableName, ymd desc
end
