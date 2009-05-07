/****** Object:  StoredProcedure [dbo].[pr_rpt_deepScanChronological]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- pr_rpt_deepScanChronological 'funmssql02', '2008-01-10 15:00:00.000', '2008-01-10 17:00:00.000'

CREATE procedure [dbo].[pr_rpt_deepScanChronological] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -6, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	select keyName, subkeyName,
		left(keyValue, 95) + case when len(keyValue) > 95 then ' ...' else '' end as keyValue ,
		ymd
		from (
			select
				case
					when keyName = 'Wait Statistics' then 'Waits'
					when keyName = 'CPU Scheduler' then 'CPU'
					when keyName = 'Buffer Cache Contents' then 'Buffer'
					when keyName = 'CPU Time Consumers' then 'CPU Time'
					when keyName = 'Disk IO Consumers' then 'Disk IO'
					when keyName = 'Recompiled Objects' then 'Recompiled'
					when keyName = 'Memory Allocation' then 'Memory'
					else keyName
					end as keyName,
				case
					when subkeyName = 'Nonclustered used more than clustered' then 'Bad Cluster'
					when subkeyName = 'Indexes updated but not accessed' then 'Not used'
					when keyName = 'Buffer Cache Contents' then left(subkeyName, charindex('.', subkeyName) - 1)
					when subkeyName like '%Disk IO Waiting%' then replace(subkeyName, 'Disk IO Waiting', 'IO')
					when subkeyName = 'Indexes not being used' then 'Index not used'
					when subkeyName like '%Proportion%' then replace(subkeyName, 'Proportion', '%')
					when subkeyName = 'Tables not indexed' then 'Not Indexed'
					when subkeyName = 'Available Paging File' then 'Paging Available'
					when subkeyName = 'External Reservation' then 'External Resvd'
					else subkeyName
					end as subkeyName,

				case
					when subkeyName = 'Nonclustered used more than clustered'
						then replace(replace(replace(replace(replace(replace(replace(replace(substring(keyValue, charindex(' on ', keyValue) + 4, 5000), 'may be better suited as a clustered index. Bookmark scans (which use a combination of clustered and non-clustered) ', ''), ' show ', ' ('), '. There were', ' :: '), 'seeks against index', ' seeks using #'), '. therewere', ' :: '), 'against the clustered index.', 'w/ cluster)'), 'against the clusteredindex.', 'w/ cluster)'), space(2), space(1))
					when keyName = 'Buffer Cache Contents'
						then substring(subkeyName, charindex('.', subkeyName) + 1, 100) + ' ::: ' + keyValue
					when subkeyName = 'Tables not indexed'
						then replace(replace(keyValue, 'passes have been made against ', 'scans of'), 'which does not have an index', 'which is unindexed')
					when subkeyName = 'Indexes not being used'
						then replace(replace(replace(replace(replace(replace(replace(replace(keyValue, 'have been made against ', 'of '), '(clustered index 1),', ''), ' that were unable to use the index', ''), 'scans', 'table scans'), '(nonclustered index 2),', ''), '(nonclustered index 3),', ''), '(nonclustered index 4),', ''), '(nonclustered index 5),', '')
					when keyName = 'CPU Time Consumers'
						then left(keyValue, charindex(space(1), keyValue)) + ' runs ' + substring(keyValue, charindex('consumed', keyValue), 500)
					when keyName = 'Disk IO Consumers'
						then left(keyValue, charindex(' over', keyValue)) + substring(keyValue, charindex('consumed', keyValue), 500)
					else keyValue
					end as keyValue,
				left(right(convert(varchar(20), ymd, 120), 8), 5) as ymd
				from deepSQLStats (nolock)
				where serverName = @cServerName
					and ymd >= @dStartDate
					and ymd < @dEndDate
					and keyName <> ''
			) a
			order by keyName, subkeyName,
				case
					when keyName in ('CPU Time', 'Disk IO', 'Buffer') then substring(keyValue, charindex(':::', keyValue), 500)
					when subkeyName = 'Index not used' then substring(keyValue, charindex('of', keyValue) + 3, 5000)
					when subkeyName = 'Bad Cluster' then left(keyValue, charindex(space(1), keyValue)) + substring(keyValue, charindex('#', keyValue), 5) -- substring(keyValue, charindex('(', keyValue) + 1, 100)
					when subkeyName = 'Not Indexed' then substring(keyValue, charindex('against', keyValue) + 8, 5000)
					when subkeyName = 'Not used' then left(keyValue, charindex(' has been updated', keyvalue) - 1)
					when keyname = 'recompiled' then substring(keyValue, charindex('per hour', keyValue) + 9, 5000)
					when keyName in ('cpu', 'memory', 'waits') then ''
					else ''
					end,
				ymd
end
GO
