select
	c.serverName, b.ymd,
	a.programName, a.installDate, a.version
	into #installedSoftware
	from runs_data a
	join runs b on a.ukey_run = b.ukey
	join notification..dm_servers c on a.ukey_server = c.ukey
		and c.serverName in ('appweb03', 'appweb01', 'uatmsweb02', 'uatmsweb03', 'appweb02')
	where b.ymd >= dateAdd(week, -1, getDate())
	order by b.ymd desc

select
	a.programName,

	max(case when b.serverName = 'appweb01' then b.installDate else '' end) as appweb01_installDate,
	max(case when b.serverName = 'appweb01' then b.version else '' end) as appweb01_version,

	max(case when b.serverName = 'appweb02' then b.installDate else '' end) as appweb02_installDate,
	max(case when b.serverName = 'appweb02' then b.version else '' end) as appweb02_version,

	max(case when b.serverName = 'appweb03' then b.installDate else '' end) as appweb03_installDate,
	max(case when b.serverName = 'appweb03' then b.version else '' end) as appweb03_version,

	max(case when b.serverName = 'uatmsweb02' then b.installDate else '' end) as uatmsweb02_installDate,
	max(case when b.serverName = 'uatmsweb02' then b.version else '' end) as uatmsweb02_version,

	max(case when b.serverName = 'uatmsweb03' then b.installDate else '' end) as uatmsweb03_installDate,
	max(case when b.serverName = 'uatmsweb03' then b.version else '' end) as uatmsweb03_version

	from (
		select serverName, ymd, programName
			from (
				select distinct programName from #installedSoftware
				) a,
				(
				select serverName, max(ymd) as ymd
					from #installedSoftware
					group by serverName
				) b
		) a
	left outer join #installedSoftware b on a.serverName = b.serverName
		and a.ymd = b.ymd
		and a.programName = b.programName

	group by a.programName


drop table #installedSoftware
