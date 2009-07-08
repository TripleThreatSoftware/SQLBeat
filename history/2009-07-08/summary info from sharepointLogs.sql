select *
	from sharepointLogs (nolock)
	where level in ('Unexpected')
		and ymd >= '2009-06-17'
	order by ymd desc

select message, count(*), min(ymd), max(ymd)
	from sharepointLogs (nolock)
	where level in ('Unexpected')
		and ymd >= '2009-06-17'
	group by message
