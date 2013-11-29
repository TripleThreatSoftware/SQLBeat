exec pr_graph_serverPerformanceSummary 'mssql06-ny'

select ymd, AVG(processorLoad) as avgLoad, MAX(processorLoad) as maxLoad
	from configuration..processorLoadLog
	where ukey_server = 12
		and ymd > '2013-11-28'
	group by ymd
	order by ymd
