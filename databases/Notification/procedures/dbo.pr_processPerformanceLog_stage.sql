/****** Object:  StoredProcedure [dbo].[pr_processPerformanceLog_stage]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_processPerformanceLog_stage]
as
begin

	declare @nMaxUkey bigint
	set @nMaxUkey = (select max(ukey) from performanceLog_stage (nolock))

	insert into dm_performanceObjects (objectName)
	select a.objectName
		from (select distinct objectName from performanceLog_stage (nolock) where ukey <= @nMaxUkey) a
		left outer join dm_performanceObjects b (nolock) on a.objectName = b.objectName
		where b.ukey is null

	insert into dm_performanceCounters (counterName)
	select a.counterName
		from (select distinct counterName from performanceLog_stage (nolock) where ukey <= @nMaxUkey) a
		left outer join dm_performanceCounters b (nolock) on a.counterName = b.counterName
		where b.ukey is null

	-- get rid of duplicates
	delete performanceLog_stage with (rowlock)
		from performanceLog_stage a
		join dm_servers b (nolock) on a.serverName = b.serverName
		join dm_performanceObjects c (nolock) on a.objectName = c.objectName
		join dm_performanceCounters d (nolock) on a.counterName = d.counterName

		left outer join performanceLog e (nolock) on a.runStamp = e.runStamp
			and b.ukey = e.ukey_server
			and c.ukey = e.ukey_object
			and d.ukey = e.ukey_counter
			and a.ukey = e.ukey

		where e.ukey is not null

	insert into performanceLog (runStamp, ymd, ukey_server, ukey_object, ukey_counter, instanceName, counterValue, counterType, ukey)
	select
		a.runStamp,
		a.ymd,
		b.ukey as ukey_server,
		c.ukey as ukey_object,
		d.ukey as ukey_counter,
		a.instanceName,
		a.counterValue,
		a.counterType,
		a.ukey

		from performanceLog_stage a (nolock)
		join dm_servers b (nolock) on a.serverName = b.serverName
		join dm_performanceObjects c (nolock) on a.objectName = c.objectName
		join dm_performanceCounters d (nolock) on a.counterName = d.counterName

		where a.ukey <= @nMaxUkey

	delete from performanceLog_stage with (rowlock)
		where ukey <= @nMaxUkey
end


--update performanceLog_stage with (rowlock)
--	set runStamp = convert(bigint,
--			convert(varchar(4), datePart(year, ymd)) +
--			dbo.fn_padl(convert(varchar(2), datePart(month, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(2), datePart(day, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(2), datePart(hour, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(2), datePart(minute, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(2), datePart(second, ymd)), 2, '0') +
--			dbo.fn_padl(convert(varchar(3), datePart(millisecond, ymd)), 3, '0')
--		)
--	where runStamp = 20071012101303660
GO
