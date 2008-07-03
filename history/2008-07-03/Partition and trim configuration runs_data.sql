declare @nUkeyRun bigint
set @nUkeyRun = (select min(ukey) from runs (nolock) where ymd >= convert(varchar(10), dateAdd(day, -3, getDate()), 120))

if exists (select top 1 [name] from sysobjects where [name] = 'runs_data_stage')
	drop table runs_data_stage

select
	distinct *
	into runs_data_stage
	from runs_data (nolock)
	where ukey_run < @nUkeyRun

insert into runs_data_stage (instance, keyValue, ukey, ukey_counter, ukey_keyName, ukey_run, ukey_server)
select distinct instance, keyValue, ukey, ukey_counter, ukey_keyName, ukey_run, ukey_server
	from runs_data
	where ukey_run < @nUkeyRun

create clustered index ix_runs_data_stage_run on runs_data_stage (ukey_run) with fillfactor = 100

exec pr_partitionLinkedTableDaily 'runs_data_stage', 'ukey_run', 'runs', 'ukey', 'ymd', 'ukey_run, ukey_server, ukey_counter, instance, ukey_keyName, ukey', 0

delete from runs_data with (tablock) where ukey_run < @nUkeyRun

drop table runs_data_stage
truncate table runs_data
