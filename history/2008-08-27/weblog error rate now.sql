	declare @dStartDate dateTime
	declare @dEndDate dateTime

	set @dEndDate = dateAdd(hour, -12, convert(varchar(10), getDate(), 120))
	set @dStartDate = dateAdd(day, -7, @dEndDate)

--	select ukey_site, ukey_uriStem,
--		count(*) as numSeen,
--		min(ymd) as firstSeen,
--		max(ymd) as lastSeen
--		into #errorsSeen
--		from v_fact_weblogs_all
--		where requestStatus = '404'
--			and ymd >= @dStartDate
--			and ymd < dateAdd(day, 1, @dEndDate)
--		group by ukey_site, ukey_uriStem

	select
		a.friendlyName as siteName,
		case
			when a.friendlyName like '%doepublic%' and d.uriStem like '%ayp%' then 'AYP'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%sb10%' then 'SB10'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%finances%' then 'Finances'
			when a.friendlyName like '%portal%' and d.uriStem like '%studentprofile%' then 'Student Profile'
			when a.friendlyName like '%portal%' and d.uriStem like '%gradcoach%' then 'Grad Coach'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%title1%' then 'Title 1'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%nutrition%' then 'School Nutrition'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%curriculum%' then 'Curriculum'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%doe%' then 'DOE'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%login%' then 'Login'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%charterschool%' then 'Charter School'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%thematicmaps%' then 'AYP'
--			when a.friendlyName like '%doepublic%' and d.uriStem like '%gshs%' then 'GSHS'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%uds%' then 'UDS'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%sla%' then 'SLA'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%exceptionalstudents%' then 'Exceptional Students'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%pcgenesis%' then 'PC Genesis'
			else ''
			end as subsite,
		d.uriStem,

		a.numRequests as numErrors,
		dateDiff(hour, a.firstSeen, a.lastSeen) as hours,
		convert(decimal(20,6), convert(decimal(20,6), a.numRequests) / convert(decimal(20,6), dateDiff(hour, @dStartDate, @dEndDate))) as errorsPerHour

		from (
			select
				c.friendlyName,
				ukey_uriStem,
				sum(numSeen) as numRequests,
				convert(varchar(10), min(firstSeen), 120) as firstSeen,
				convert(varchar(10), max(lastSeen), 120) as lastSeen
				from #errorsSeen a
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and c.friendlyName like 'PRO%'
				group by c.friendlyName, ukey_uriStem
			) a

		join dm_uriStem d (nolock) on a.ukey_uriStem = d.ukey

		where dateDiff(hour, a.firstSeen, a.lastSeen) > 0

	select
		a.friendlyName as siteName,
		case
			when a.friendlyName like '%doepublic%' and d.uriStem like '%ayp%' then 'AYP'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%sb10%' then 'SB10'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%finances%' then 'Finances'
			when a.friendlyName like '%portal%' and d.uriStem like '%studentprofile%' then 'Student Profile'
			when a.friendlyName like '%portal%' and d.uriStem like '%gradcoach%' then 'Grad Coach'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%title1%' then 'Title 1'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%nutrition%' then 'School Nutrition'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%curriculum%' then 'Curriculum'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%doe%' then 'DOE'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%login%' then 'Login'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%charterschool%' then 'Charter School'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%thematicmaps%' then 'AYP'
--			when a.friendlyName like '%doepublic%' and d.uriStem like '%gshs%' then 'GSHS'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%uds%' then 'UDS'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%sla%' then 'SLA'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%exceptionalstudents%' then 'Exceptional Students'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%pcgenesis%' then 'PC Genesis'
			else ''
			end as subsite,

		sum(a.numRequests) as numErrors,
		convert(decimal(20,6), convert(decimal(20,6), sum(a.numRequests)) / convert(decimal(20,6), dateDiff(hour, @dStartDate, @dEndDate))) as errorsPerHour

		from (
			select
				c.friendlyName,
				ukey_uriStem,
				sum(numSeen) as numRequests,
				convert(varchar(10), min(firstSeen), 120) as firstSeen,
				convert(varchar(10), max(lastSeen), 120) as lastSeen
				from #errorsSeen a
				join dm_sites c (nolock) on a.ukey_site = c.ukey
					and c.friendlyName like 'PRO%'
				group by c.friendlyName, ukey_uriStem
			) a

		join dm_uriStem d (nolock) on a.ukey_uriStem = d.ukey

		where dateDiff(hour, a.firstSeen, a.lastSeen) > 0
		group by a.friendlyName, case
			when a.friendlyName like '%doepublic%' and d.uriStem like '%ayp%' then 'AYP'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%sb10%' then 'SB10'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%finances%' then 'Finances'
			when a.friendlyName like '%portal%' and d.uriStem like '%studentprofile%' then 'Student Profile'
			when a.friendlyName like '%portal%' and d.uriStem like '%gradcoach%' then 'Grad Coach'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%title1%' then 'Title 1'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%nutrition%' then 'School Nutrition'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%curriculum%' then 'Curriculum'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%doe%' then 'DOE'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%login%' then 'Login'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%charterschool%' then 'Charter School'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%thematicmaps%' then 'AYP'
--			when a.friendlyName like '%doepublic%' and d.uriStem like '%gshs%' then 'GSHS'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%uds%' then 'UDS'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%sla%' then 'SLA'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%exceptionalstudents%' then 'Exceptional Students'
			when a.friendlyName like '%doepublic%' and d.uriStem like '%pcgenesis%' then 'PC Genesis'
			else ''
			end



--	drop table #errorsSeen
--end
