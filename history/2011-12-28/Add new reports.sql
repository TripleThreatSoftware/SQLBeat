select * from reportMetaData

insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'Log File Performance', 'SQL', 'pr_graph_logFilePerformance', 'ManyGraphs')
insert into reportMetaData (ukey_parent, reportName, reportGroup, storedProcedureName, reportType) values (1, 'TempDB Performance', 'SQL', 'pr_graph_tempdbPerformance', 'ManyGraphs')
