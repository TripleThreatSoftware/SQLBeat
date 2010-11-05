select * from jobs order by jobname

select top 100 * from jobHIstory where ukey_job = 13 order by ymd desc
declare @bIsSUccess bit
exec pr_job_runsteps 13, @bIsSUccess
