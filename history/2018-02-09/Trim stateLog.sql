--select top 100 * from stateLog
--select top 100 * from dm_stateKeys

--drop table dm_stateValues

-- alter table dm_stateKeys add lastData dateTime default getDate()
--sp_helptext 'pr_updateState'

delete from stateLog with (tablock) where ymd < '2013-01-01'
go
delete from stateLog with (tablock) where ymd < '2014-01-01'
go
delete from stateLog with (tablock) where ymd < '2015-01-01'
go
delete from stateLog with (tablock) where ymd < '2016-01-01'
go
delete from stateLog with (tablock) where ymd < '2013-01-01'
go
delete from stateLog with (tablock) where ymd < dateadd(month, -12, getDate())
go

select distinct ukey_stateKey into #usedKeys from stateLog (nolock)
delete dm_stateKeys
	from dm_stateKeys a
	left outer join #usedKeys b on a.ukey = b.ukey_stateKey
	where b.ukey_stateKey is null
go
