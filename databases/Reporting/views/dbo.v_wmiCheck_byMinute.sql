SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER view [dbo].[v_wmiCheck_byMinute]
as

	select
		a.ukey_server, d.ymd, c.keyName, b.counterName, a.instance, a.keyValue
		from configuration.dbo.v_runs_data_all a
		join configuration.dbo.dm_counters b (nolock) on a.ukey_counter = b.ukey
		join configuration.dbo.dm_keyNames c (nolock) on a.ukey_keyName = c.ukey
		join configuration.dbo.runs d (nolock) on a.ukey_run = d.ukey
		where d.ymd >= dateAdd(day, -7, getDate())

GO
