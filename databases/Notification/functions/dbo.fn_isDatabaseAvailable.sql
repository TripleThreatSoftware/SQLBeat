--select dbo.fn_isDatabaseAvailable('switch_ap')
alter function fn_isDatabaseAvailable(@cDatabaseName varchar(200))
returns bit
as
begin
	declare @bReturn bit
	set @bReturn = 1

	if (
		select [name]
			from master.dbo.sysdatabases
			where [name] = @cDatabaseName
				and (
					(status & 32) = 32 -- loading
					or (status & 64) = 64 -- prerecovery
					or (status & 128) = 128 -- recovery
					or (status & 512) = 512 -- offline
					or (status & 4096) = 4096 -- single user
					)
		) = @cDatabaseName
		or databaseproperty(@cDatabaseName, 'IsSuspect') = 1
		or databasepropertyex(@cDatabaseName, 'Status') = 'SUSPECT'
	begin
		set @bReturn = 0
	end

	return @bReturn
end
