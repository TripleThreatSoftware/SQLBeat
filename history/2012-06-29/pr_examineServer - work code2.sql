			select *
				from jobStepHistory a (nolock)
				join dm_serverJobSteps b (nolock) on a.ukey_jobStep = b.ukey
					and a.ukey_job = b.ukey_job
					and b.ukey_server = 45
				join dm_serverJobs c (nolock) on b.ukey_job = c.ukey
					and a.ukey_job = c.ukey
					and c.ukey_server = 45
					and c.ukey = 514

				join jobHistory d (nolock) on d.ukey_job = 514
					and d.ukey_server = 45
					--and d.ymd = @dJobFailure
					and a.ukey_jobHistory = d.ukey

				where a.ukey_server = 45
				order by a.ymd desc

select top 500 * from jobStepHistory where ukey_server = 45 and ukey_job = 514 and ymd = '2012-06-29 10:02:00.000' order by ukey
