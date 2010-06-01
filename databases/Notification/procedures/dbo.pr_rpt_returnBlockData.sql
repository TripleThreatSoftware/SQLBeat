SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_rpt_returnBlockData] (@cMachineID varchar(100), @cDashboard varchar(100), @nUkeyBlock int)
as
begin
	declare @cSQLString nvarchar(4000)
	declare @cBlockData varchar(500)

	set @cBlockData = (
		select top 1 b.blockData
			from dashboardBlocks a (nolock)
			join dm_blocks b on a.ukey_block = b.ukey
			where a.machineID = @cMachineID
				and a.ukey = @nUkeyBlock
		)

	create table #output (keyName varchar(500), keyValue_string varchar(1000), keyValue_numeric varchar(500))

	if exists (select top 1 [name] from sysobjects where [name] = @cBlockData)
	begin
		set @cSQLString = 'exec [' + @cBlockData + '] @cMachineID = ''' + @cMachineID + ''''

		insert into #output (keyName, keyValue_string, keyValue_numeric)
		exec sp_executeSQL @cSQLString
	end

	select keyName,
		case
			when isnull(keyValue_string, '') <> '' then keyValue_string
			else '<div align="right">' + dbo.fn_returnFormattedNumber(keyValue_numeric) + '</div>'
			end as keyvalue
		from #output

	drop table #output
end
