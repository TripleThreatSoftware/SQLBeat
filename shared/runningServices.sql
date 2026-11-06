set nocount on

create table #results (outputLine varchar(500))

insert into #results
exec master.dbo.xp_cmdshell 'net start'

delete from #results
	where outputLine like '%these windows services are started%'
		or outputLine is null
		or outputLine like '%command completed%'
		or outputLine like '%timeout%'
		or outputLine like '%dbnetlib%'
		or outputLine like '%login failed%'
		or outputLine like '%no user selected%'

update #results
	set outputLine = rtrim(ltrim(replace(replace(replace(outputLine, char(9), ''), char(13), ''), '  ', ' ')))

update #results
	set outputLine = substring(outputLine, 2, len(outputLine))
	where left(outputLine, 1) = ' '

select distinct outputLine as serviceName
	from #results
	where outputLine <> ''

drop table #results

set nocount off

