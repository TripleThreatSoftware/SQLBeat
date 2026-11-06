/****** Object:  StoredProcedure [dbo].[pr_returnPerformanceStatThresholds]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_returnPerformanceStatThresholds]
as
begin

	select a.*
		from (
			select
				a.ukey,
				isnull(b.serverName, 'ALL') as serverName,
				isnull(d.objectName, 'ALL') as objectName,
				isnull(c.counterName, 'ALL') as counterName,
				isnull(a.instanceName, '') as instanceName,
				convert(int, a.minValue) as minValue,
				convert(int, a.maxValue) as maxValue
				from dm_performanceStatThresholds a (nolock)
				left outer join dm_servers b (nolock) on a.ukey_server = b.ukey
				left outer join dm_performanceCounters c (nolock) on a.ukey_counter = c.ukey
				left outer join dm_performanceObjects d (nolock) on a.ukey_object = d.ukey
			) a
		order by serverName, objectName, counterName, minValue, maxValue

end
GO
