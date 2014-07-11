--select max(len(uristem)) from dm_uristem (nolock)

--select top 100 len(uristem), count(*) from dm_uristem (nolock) group by len(uristem) order by len(uristem) desc

delete from dm_uristem where len(uristem) > 800
go

alter table dm_uristem alter column uristem varchar(800)
go

create index ix_uristem_uristem_ukey on dm_uristem (uristem, ukey) with fillfactor = 80
go
