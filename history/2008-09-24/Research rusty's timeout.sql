select *
	from processLog (nolock)
	where servername = 'sqlcluster01'
		and ymd <= '2008-09-23 13:30:06'
		and ymd >= '2008-09-23 11:00:08'
		and command <> 'awaiting command'
		and bufferContents like '%sessionlog%'
	order by ymd, spid


select *
	from processLog (nolock)
	where servername = 'sqlcluster01'
		and ymd = '2008-09-23 13:28:21.530'
	order by ymd, spid
