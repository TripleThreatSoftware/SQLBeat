use [Weblogs]
declare @dStartProcessing dateTime
declare @dToday dateTime
set @dStartProcessing = (select isnull(max(ymd), convert(varchar(10), getDate(), 120)) from fact_weblogs_stage_hist (nolock) where stepName = 'Processing Sources')

create table #dates (ymd dateTime)
insert into #dates
select distinct ymd from ( select distinct convert(varchar(10), minYMD, 120) as ymd from dm_sourceFiles where dateAdded >= @dStartProcessing
union select distinct convert(varchar(10), maxYMD, 120) as ymd from dm_sourceFiles where dateAdded >= @dStartProcessing ) a
where ymd is not null

set @dToday = ''

while exists (select top 1 ymd from #dates where ymd > @dToday and ymd >= dateAdd(month, -3, getDate()))
begin
	select top 1 @dToday = ymd from #dates where ymd > @dToday and ymd >= dateAdd(month, -3, getDate()) order by ymd

	insert into fact_weblogs_stage_hist (stepName) values ('Processing Page ' + convert(varchar(10), @dToday, 120) + '.')
	exec pr_mart_page @dToday, @dToday
	insert into fact_weblogs_stage_hist (stepName) values ('Processing User ' + convert(varchar(10), @dToday, 120) + '.')
	exec pr_mart_userAgent @dToday, @dToday
	insert into fact_weblogs_stage_hist (stepName) values ('Processing Site ' + convert(varchar(10), @dToday, 120) + '.')
	exec pr_mart_site @dToday, @dToday
end

select top 100 * from fact_weblogs_stage_hist order by ymd desc


	exec pr_mart_page '2012-01-09', '2012-01-10'
	exec pr_mart_userAgent '2012-01-09', '2012-01-10'
	exec pr_mart_site '2012-01-09', '2012-01-10'
