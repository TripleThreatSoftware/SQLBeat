SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from serverSelection
-- select * from reportMetaData where level1 = 'web03' and level2 = 'cpu' and counterName = 'processorLoad'
-- exec pr_produceReport 'ulhzbp55gdsmakaqndcjnl55', 3704, '', ''
-- exec pr_produceReport 'ulhzbp55gdsmakaqndcjnl55', null, null, 3704, '', '', 1

-- exec pr_produceReport '', 0, 0, 24903
ALTER procedure [dbo].[pr_produceReport] (@cMachineID varchar(100), @nGraphW int, @nGraphH int, @nUkeyReport int, @dStartDate dateTime = null, @dEndDate dateTime = null, @bReturnTable bit = 0)
as
begin

	if not exists (select top 1 ukey from reportMetaData where ukey = @nUkeyReport)
		return

	if isnull(@dStartDate, '') = ''
		set @dStartDate = convert(varchar(10), dateAdd(day, -7, getDate()), 120)

	if isnull(@nGraphW, 0) = 0
		set @nGraphW= 1000

	if isnull(@nGraphH, 0) = 0
		set @nGraphH = 300

	declare @cSQLString nvarchar(4000)
	declare @cWhereClause nvarchar(4000)
	declare @cDateField varchar(500)
	declare @cTableName varchar(500)
	declare @cServerField varchar(500)
	declare @cDataValue varchar(500)
	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity, dataValue varchar(500))

	select top 1
		@cSQLString = 'select ' +
			case
				when tableName like '%byDay%' then 'convert(varchar(10), [' + dateField + '], 120) as ymd, '
				else 'convert(varchar(20), [' + dateField + '], 120) as ymd, '
				end +
			'[' + dataField + '] as dataValue ' +
			'from ' + tableName + ' ',
		@cWhereClause = whereClause,
		@cDateField = dateField,
		@cTableName = tableName
		from reportMetaData (nolock)
		where ukey = @nUkeyReport

	set @cServerField = (
		select top 1 b.name
			from sysobjects a
			join syscolumns b on a.id = b.id
				and b.name in ('ukey_server', 'serverName')
				and a.name = @cTableName
		)

	set @cSQLString = @cSQLString +
		'where 3=3 '

	--set @cSQLString = @cSQLString +
	--	'where ' +
	--		case
	--			when @cServerField = 'ukey_server' then 'ukey_server in (select ukey_server from serverSelection where machineID = ''' + @cMachineID + ''')'
	--			else 'serverName in (select serverName from notification.dbo.dm_servers where ukey in (select ukey_server from serverSelection where machineID = ''' + @cMachineID + '''))'
	--			end

	if isnull(@dStartDate, '') <> ''
		set @cSQLString = @cSQLString + ' and [' + @cDateField + '] >= ''' + convert(varchar(20), @dStartDate, 120) + ''''
	if isnull(@dEndDate, '') <> ''
		set @cSQLString = @cSQLString + ' and [' + @cDateField + '] <= ''' + convert(varchar(20), @dEndDate, 120) + ''''

	if isnull(@cWhereClause, '') <> ''
		set @cSQLString = @cSQLString + ' and (' + @cWhereClause + ')'

	print @cSQLString

	insert into #dataValues (axis_x, dataValue)
	exec sp_executeSQL @cSQLString

	if @@rowcount > 200
	begin
		print 'removing excess rows'

		delete #dataValues
			from #dataValues a
			left outer join (
				select top 200 sortOrder
					from #dataValues
					order by sortOrder desc
				) b on a.sortOrder = b.sortOrder
			where b.sortOrder is null
	end

	set @cDataValue = (select top 1 left(datavalue, 500) from #dataValues)

	if isnumeric(@cDataValue) = 1 and @bReturnTable = 0
	begin
		-- here, we think we can graph it
		update #dataValues set setName = 'Report DataSet', seriesName = 'Report DataSeries', axis_y = dataValue

		--8/20 Jason Edit.
		--exec notification.dbo.pr_generateGoogleChartsRequest @nWidth = 1000, @nHeight = 300, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
		exec notification.dbo.pr_generateGoogleChartsRequest @nWidth = @nGraphW, @nHeight = @nGraphH, @bRelativeToTotal = 0, @bAbsoluteYAxis = 1
	end
	else
	begin
		-- here, we must return a table
		select axis_x as ymd, dataValue from #dataValues
	end

	drop table #dataValues
end
