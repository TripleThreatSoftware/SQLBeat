use scheduler
go

update jobSteps
	set stepText = 'exec pr_monitorURLs', stepName = 'pr_monitorURLs', isCommand = 0, stepDatabase = 'websiteMonitor'
	where ukey_job in (select ukey from jobs where jobname = 'Monitor websites')
		and stepNumber = 1
