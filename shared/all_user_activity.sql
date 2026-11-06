declare @nSpid int
declare @nThisHandle binary(20)
declare @cSPIDCommand varchar(3000)
declare @cSQLString nvarchar(4000)

set nocount on

select net_address, spid, sql_handle, convert(varchar(3000), '') as bufferContents
	into #processes
	from master.dbo.sysprocesses (nolocK)

create table #bufferResults (eventType varchar(200), parameters varchar(200), eventInfo varchar(1000))

set @nSPID = 50

while exists (select top 1 * from #processes where spid > @nSPID)
begin
	select top 1 @nSPID = spid, @nThisHandle = sql_handle from #processes where spid > @nSPID order by spid

	set @cSPIDCommand = null

	if @nThisHandle is not null
		set @cSPIDCommand = (select substring(text, 1, 3000) from ::fn_get_sql(@nThisHandle))

	if @cSPIDCommand is null
	begin
		set @cSQLString = 'dbcc inputbuffer(' + convert(varchar(10), @nSPID) + ') with no_infomsgs'

		insert into #bufferResults
		exec sp_executeSQL @cSQLString

		set @cSPIDCommand = (select top 1 eventInfo from #bufferResults)
		truncate table #bufferResults
	end

	update #processes
		set bufferContents = @cSPIDCommand
		where spid = @nSPID
end

select '||' + convert(varchar(10), spid) + '||' + net_address + '||' + isnull(buffercontents, '') 
	from #processes 
	where spid > 50
	
drop table #processes
drop table #bufferResults