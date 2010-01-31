alter procedure [dbo].[pr_rpt_jobRuntimeHistory] (@cServerName varchar(100), @nUkeyJob int)
as
begin

	create table #dataValues (seriesName varchar(100), setName varchar(200), axis_x varchar(100), axis_y decimal(10,2), sortOrder int identity)

	insert into #dataValues
	select
		'Avg' as seriesName,
		'Avg' as setName,
		right(convert(varchar(10), a.ymd, 120), 5) as ymd,
		avg(runningSeconds)
		from jobHistory a (nolock)
		join dm_serverJobs b (nolock) on a.ukey_job = b.ukey
			and a.ukey_server = b.ukey_server
		where (a.ukey_server = (select top 1 ukey from dm_servers (nolock) where serverName = @cServerName) or isnull(@cServerName, '') = '')
			and a.ymd >= dateAdd(week, -3, convert(varchar(10), getDate(), 120))
			and (a.ukey_job = @nUkeyJob or isnull(@nUkeyJob, 0) = 0)
			and runningSeconds <> 0
		group by convert(varchar(10), a.ymd, 120)
		order by convert(varchar(10), a.ymd, 120)

	insert into #dataValues
	select
		'Max' as seriesName,
		'Max' as setName,
		right(convert(varchar(10), a.ymd, 120), 5) as ymd,
		avg(runningSeconds)
		from jobHistory a (nolock)
		join dm_serverJobs b (nolock) on a.ukey_job = b.ukey
			and a.ukey_server = b.ukey_server
		where (a.ukey_server = (select top 1 ukey from dm_servers (nolock) where serverName = @cServerName) or isnull(@cServerName, '') = '')
			and a.ymd >= dateAdd(week, -3, convert(varchar(10), getDate(), 120))
			and (a.ukey_job = @nUkeyJob or isnull(@nUkeyJob, 0) = 0)
		group by convert(varchar(10), a.ymd, 120)
		order by convert(varchar(10), a.ymd, 120)

	exec notification..pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bAbsoluteYAxis = 1

	drop table #dataValues
end
