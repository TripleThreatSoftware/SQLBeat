/****** Object:  StoredProcedure [dbo].[pr_notificationTemp_statCheck]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
			create procedure [dbo].[pr_notificationTemp_statCheck]
			as
			begin
				insert into performanceLog_stage (serverName, [objectName], [counterName], [instanceName], counterValue, counterType, runStamp)
				select
					'web02' as serverName,
					a.object_name,
					a.counter_name,
					a.instance_name,
					case
						when b.counter_name is not null and b.cntr_value <> 0
							then convert(decimal(30,4), 100 * convert(decimal(30,4), a.cntr_value) / convert(decimal(30,4), b.cntr_value))
							else convert(decimal(30,4), a.cntr_value)
							end as cntr_value,
					a.cntr_type,
					20261106093001493 as runStamp
					from [web02].master.dbo.sysperfinfo a
					left outer join [web02].master.dbo.sysperfinfo b on a.object_name = b.object_name
						and a.instance_name = b.instance_name
						and b.cntr_type in (1073939458, 1107494144, 1073939712, 1073939459, 1073939457)
						and replace(replace(b.counter_name, 'ratio', ''), 'base', '') like rtrim(ltrim(replace(replace(a.counter_name, 'ratio', ''), 'base', ''))) + '%'
						and a.cntr_type in (537003264, 549585920, 4260864, 805438464, 591463680, 575735040, 592512256)
					where a.cntr_type not in (1073939458, 1107494144, 1073939712, 1073939459, 1073939457)
			 end
GO
