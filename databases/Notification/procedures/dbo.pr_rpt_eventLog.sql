create procedure pr_rpt_eventLog (@nUkeyServer int, @nNumHours int = 48)
as
begin
	declare @cComputerName varchar(200)
	set @cComputerName = (select top 1 serverName from dm_servers where ukey = @nUkeyServer)

	select timeWritten, sourceName, category, message
		from eventLog (nolock)
		where timeWritten >= dateAdd(hour, -@nNumHours, getDate())
			and computerName = @cComputerName
		order by timeWritten desc
end
