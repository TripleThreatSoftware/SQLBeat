-- select top 100 * from indexPerformanceLog

select
	tableName, indexName,
	sum(user_seeks) as seeks,
	sum(user_scans) as scans,
	sum(user_lookups) as lookups,
	sum(user_updates) as updates,
	count(distinct a.servername) as numNodes,
	'drop index [' + tablename + '].[' + indexname + ']'
	from indexPerformanceLog a
	join (select servername, max(ymd) as ymd from indexPerformanceLog group by servername) b on a.servername = b.servername
		and a.ymd = b.ymd
	where databasename in ('AppDb_a', 'AppDb_b')
		and indexName <> 'NONE'
	group by tableName, indexName
	having sum(user_seeks) + sum(user_scans) + sum(user_lookups) = 0
	order by tableName, indexName
