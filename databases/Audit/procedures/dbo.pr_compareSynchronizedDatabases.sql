SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_compareSynchronizedDatabases]
as
begin
	declare @cSourceServer varchar(500)
	declare @cTargetServer varchar(500)

	declare @cSourceDatabase varchar(500)
	declare @cTargetDatabase varchar(500)

	declare @nUkey int

	set @nUkey = 0

	while exists (select top 1 ukey from synchronizedDatabases where ukey > @nUkey)
	begin
		select top 1
			@nUkey = ukey,
			@cSourceServer = sourceServer,
			@cTargetServer = targetServer,
			@cSourceDatabase = sourceDatabase,
			@cTargetDatabase = targetDatabase
			from synchronizedDatabases
			where ukey > @nUkey
			order by ukey

		exec pr_compareDatabases @cSourceServer, @cSourceDatabase, @cTargetServer, @cTargetDatabase, 1, 1

		update synchronizedDatabases set lastCheck = getDate() where ukey = @nUkey
	end
end
