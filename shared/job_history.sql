set nocount on

declare @dStartDate dateTime
declare @nMinuteInterval int
declare @cSQLString nvarchar(4000)
declare @dRightNow dateTime

if @dStartDate is null
begin
	set @dStartDate = dateAdd(day, -1, getDate())
	set @dStartDate = dateAdd(hour, -datePart(hour, @dStartDate), @dStartDate)
	set @dStartDate = convert(varchar(16), dateAdd(minute, -datePart(minute, @dStartDate), @dStartDate), 120)
end

set @nMinuteInterval = isnull(@nMinuteInterval, 10)

create table #days (ukey int identity, ymdStart dateTime, ymdStop dateTime)
create table #results (ymdStart dateTime, jobName varchar(1000))

set @dRightNow = @dStartDate

while @dRightNow < getDate()
begin
	insert into #days (ymdStart, ymdStop) values (@dRightNow, dateAdd(second, -1, dateAdd(minute, @nMinuteInterval, @dRightNow)))

	set @dRightNow = dateAdd(minute, @nMinuteInterval, @dRightNow)
end

insert into #results
select distinct
	a.ymdStart, isnull(c.[name], space(0)) as jobName
	from #days a
	left outer join (
		select 
			job_id,
			convert(dateTime, left(run_date, 4) + '-' + left(right(run_date, 4), 2) + '-' + right(run_date, 2) + ' ' + 
				left(replicate('0', 6 - len(rtrim(run_time))) + rtrim(ltrim(run_time)), 2) + ':' + 
					left(right(replicate('0', 6 - len(rtrim(run_time))) + 
					rtrim(ltrim(run_time)), 4), 2) + ':' + 
					right(replicate('0', 6 - len(rtrim(run_time))) + rtrim(ltrim(run_time)), 2) + '.000') as startTime,
			convert(decimal(10,4), SUBSTRING(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),3,2)) + 1 + 
			convert(decimal(10,4), left(RIGHT('000000' + CAST(run_duration AS VARCHAR(10)),6),2)) * 60 as runtime_minutes
		 
			from msdb.dbo.sysjobhistory 
			where --run_status = 1 
				step_id = 0
				and run_date >= convert(int, replace(convert(varchar(10), @dStartDate, 120), '-', ''))
		) b on b.startTime <= a.ymdStop
			and dateAdd(minute, b.runtime_minutes, b.startTime) >= a.ymdStart
	left outer join msdb..sysjobs c on b.job_id = c.job_id

delete from #results
	where isnull(jobName, '')  like '%sql notification%'
		or isnull(jobName, '') like '%transaction log%'
		or isnull(jobName, '') like '%agent history%'
		or isnull(jobName, '') like '%replication%'
		or isnull(jobName, '') like '%sql_info%'

insert into #results 
select ymdStart, '******************************************************************************************************' as jobName
	from #days

select 
	convert(varchar(20), ymdStart, 120) + '|||' + jobName
	from #results
	order by ymdStart, case when left(jobName, 1) = '*' then 1 else 2 end, jobName

drop table #results
drop table #days