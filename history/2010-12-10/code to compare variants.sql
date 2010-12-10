USE Audit

declare @cObjectName varchar(200)
set @cObjectName = 'vwleasecriticaldates'

select
	serverName, databaseName, objectName, sum(notification.dbo.fn_checkSum(objectText)) as textCheckSum
	into #allVersions
	from auditData_objectText (nolock)
	where objectName = @cObjectName
		and isCurrent = 1
		and serverName in (select distinct serverName from notification.dbo.dm_servers where isEnabled = 1)
	group by serverName, databaseName, objectName

select distinct
	textCheckSum ,
	convert(varchar(max), null) as objectText,
	identity(int) as ukey
	into #variants
	from #allVersions

declare @nUkeyVariant int
declare @cObjectText varchar(max)
create table #text (objectText varchar(8000), ukey int identity)
create clustered index ix_tmp_text_ukey on #text (ukey) with fillfactor = 60

set @nUkeyVariant = 0

while exists (select top 1 ukey from #variants where ukey > @nUkeyVariant)
begin
	select top 1
		@nUkeyVariant = ukey
		from #variants
		where ukey > @nUkeyVariant
		order by ukey

	set @cObjectText = ''
	delete from #text

	insert into #text (objectText)
	select a.objectText
		from auditData_objectText a
		join (
			select top 1 serverName, databaseName, objectName
				from #allVersions
				where textChecksum in (select top 1 textChecksum from #variants where ukey = @nUkeyVariant)
			) b on a.serverName = b.serverName
			and a.databaseName = b.databaseName
			and a.objectName = b.objectName
		where a.isCurrent = 1
		order by a.colID, case when a.objectText like '%create%' then 1 else 2 end, a.objectText

	select @cObjectText = @cObjectText + isnull(objectText, '')
		from #text a

	update #variants set objectText = @cObjectText where ukey = @nUkeyVariant
end


select a.ukey as variant, b.serverName, b.databaseName, a.objectText
	from #variants a
	join #allVersions b on a.textChecksum = b.textChecksum
	order by a.ukey, a.objectText, b.serverName, b.databaseName

go

drop table #text
drop table #allVersions
drop table #variants
