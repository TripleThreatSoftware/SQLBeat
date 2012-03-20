select waitResource, COUNT(*)
	from processLog (nolock)
	where serverName = 'web04'
		and ymd >= DATEADD(minute, -10, getDate())
		and command <> 'awaiting command'
		and waitResource <> ''
	group by waitResource
	order by COUNT(*) desc

select top 100 *
	from processLog (nolock)
	where serverName = 'web04'
		and ymd >= DATEADD(minute, -10, getDate())
		and command <> 'awaiting command'
	order by diskIO desc
