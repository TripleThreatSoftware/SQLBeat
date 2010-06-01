SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- pr_rpt_returnBlocks '2s4zlb555jayq223jisrkt3n', 'Home'
ALTER procedure [dbo].[pr_rpt_returnBlocks] (@cMachineID varchar(100), @cDashboard varchar(100))
as
begin
	declare @cSQLString nvarchar(4000)
	declare @nUkeyBlock int
	declare @cBlockSummary varchar(500)

	declare @results table (blockTitle varchar(200), graphURL varchar(1000), statusClass varchar(200), statusMessage varchar(1000), ukey_block int)
	create table #output (graphURL varchar(8000), statusClass varchar(500), statusMessage varchar(1000))

	insert into @results (blockTitle, ukey_block)
	select b.blockTitle, a.ukey
		from dashboardBlocks a (nolock)
		join dm_blocks b on a.ukey_block = b.ukey
		join dm_dashboards c on a.ukey_dashboard = c.ukey
			and c.machineID = @cMachineID
			and c.dashboardName = @cDashboard
		where a.machineID = @cMachineID
		order by a.sortOrder, b.blockTitle

	set @nUkeyBlock = 0
	while exists (
		select top 1 a.ukey
			from dashboardBlocks a (nolock)
			join dm_dashboards c on a.ukey_dashboard = c.ukey
				and c.machineID = @cMachineID
				and c.dashboardName = @cDashboard
			where a.machineID = @cMachineID
				and a.ukey > @nUkeyBlock)
	begin
		select top 1
			@nUkeyBlock = a.ukey,
			@cBlockSummary = b.blockSummary
			from dashboardBlocks a (nolock)
			join dm_blocks b on a.ukey_block = b.ukey
			join dm_dashboards c on a.ukey_dashboard = c.ukey
				and c.machineID = @cMachineID
				and c.dashboardName = @cDashboard
			where a.machineID = @cMachineID
				and a.ukey > @nUkeyBlock
			order by a.ukey

		if exists (select top 1 [name] from sysobjects where [name] = @cBlockSummary)
		begin
			set @cSQLString = 'exec [' + @cBlockSummary + '] @cMachineID = ''' + @cMachineID + ''''

			print 'Running: ' + @cSQLString

			insert into #output (statusClass, statusMessage, graphURL)
			exec sp_executeSQL @cSQLString

			update @results
				set graphURL = b.graphURL, statusClass = b.statusClass, statusMessage = b.statusMessage
				from @results a, #output b
				where a.ukey_block = @nUkeyBlock
		end

		truncate table #output
	end

	select * from @results
	drop table #output
end
