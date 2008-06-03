IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_outages_summary]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'---- exec pr_rpt_outages_summary null, null
CREATE procedure [pr_rpt_outages_summary] (@dStartDate dateTime, @dEndDate dateTime)
as
begin
--	declare @dStartDate dateTime
--	declare @dEndDate dateTime

	set nocount on

	set @dStartDate = convert(varchar(10), isnull(@dStartDate, dateAdd(week, -1, getDate())), 120)
	set @dEndDate = convert(varchar(10), isnull(@dEndDate, getDate()), 120)

	declare @results table (groupName varchar(200), serverName varchar(200),
		connectionAttempts int, connectionFailures int, failureRate decimal(10,2), availability decimal(10,2),
		latestDrop dateTime, earliestData dateTime, latestData dateTime)

	insert into @results (groupName, serverName, connectionAttempts, connectionFailures, failureRate, availability, latestDrop, earliestData, latestData)
	select ''Websites'' as groupName, a.friendlyName as serverName,
		totalPings as connectionAttempts,
		droppedPings as connectionFailures,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		latestDrop, earliestData, latestData

		from (
			select
				case when isnull(b.friendlyName, '''') = '''' then b.websiteURL else b.friendlyName end as friendlyName,
				min(a.ymd) as earliestData,
				max(a.ymd) as latestData,
				min(case when a.isAvailable = 0 then a.ymd else null end) as earliestDrop,
				max(case when a.isAvailable = 0 then a.ymd else null end) as latestDrop,
				max(case when a.isAvailable = 1 then a.ymd else null end) as latestSuccess,
				count(distinct case when a.isAvailable = 0 then a.ukey else null end) as droppedPings,
				count(*) as totalPings
				from websiteMonitor.dbo.monitoredURLs_history a
				join websiteMonitor.dbo.monitoredURLs b on a.ukey_url = b.ukey
					and b.isEnabled = 1
				where a.ymd >= '''' + convert(varchar(10), @dStartDate, 120) + ''''
					and a.ymd < dateAdd(day, 1, '''' + convert(varchar(10), @dEndDate, 120) + '''')
				group by case when isnull(b.friendlyName, '''') = '''' then b.websiteURL else b.friendlyName end
			) a
		where droppedPings > 0

	insert into @results (groupName, serverName, connectionAttempts, connectionFailures, failureRate, availability, latestDrop, earliestData, latestData)
	select
		c.groupName,
		a.serverName,
		totalPings as connectionAttempts,
		droppedPings as connectionFailures,
		convert(decimal(10,2), convert(decimal(15,10), droppedPings)/convert(decimal(15,10), totalPings) * 100) as failureRate,
		convert(decimal(10,2), convert(decimal(15,10), (totalPings - droppedPings))/convert(decimal(15,10), totalPings) * 100) as availability,
		latestDrop, earliestData, latestData
		from (
			select
				a.serverName,
				min(a.ymd) as earliestData,
				max(a.ymd) as latestData,
				min(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as earliestDrop,
				max(case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ymd else null end) as latestDrop,
				max(case when a.isServerPingable = 1 and a.isRouterPingable = 1 then a.ymd else null end) as latestSuccess,
				count(distinct case when a.isServerPingable = 0 or a.isSQLPingable = 0 or a.isRouterPingable = 0 then a.ukey else null end) as droppedPings,
				count(*) as totalPings,
				avg(case when isnull(serverPingResults, '''') <> '''' then notification.dbo.fn_returnDigits(substring(serverPingResults, notification.dbo.fn_at(serverPingResults, ''time'', 1), 10), 0) else 0 end) as serverPing1,
				avg(case when isnull(serverPingResults, '''') <> '''' then notification.dbo.fn_returnDigits(substring(serverPingResults, notification.dbo.fn_at(serverPingResults, ''time'', 2), 10), 0) else 0 end) as serverPing2,
				avg(case when isnull(serverPingResults, '''') <> '''' then notification.dbo.fn_returnDigits(substring(serverPingResults, notification.dbo.fn_at(serverPingResults, ''time'', 3), 10), 0) else 0 end) as serverPing3,
				avg(case when isnull(serverPingResults, '''') <> '''' then notification.dbo.fn_returnDigits(substring(serverPingResults, notification.dbo.fn_at(serverPingResults, ''time'', 4), 10), 0) else 0 end) as serverPing4
				from notification.dbo.v_pingLog_all a
				where a.ymd >= '''' + convert(varchar(10), @dStartDate, 120) + ''''
					and a.ymd < dateAdd(day, 1, '''' + convert(varchar(10), @dEndDate, 120) + '''')
				group by a.serverName
			) a
		join notification.dbo.dm_servers b on a.serverName = b.serverName
			and b.isEnabled = 1
		join notification.dbo.dm_serverGroups c on b.ukey_group = c.ukey
		where droppedPings > 0

	select
		groupName, serverName, connectionAttempts, connectionFailures, failureRate, availability, latestDrop,
		convert(varchar(20), dateDiff(hour, isnull(latestDrop, earliestData), latestData)) + '' hours'' as upTime
		from @results
		order by groupName, serverName
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[v_databaseFileSizeLog_all]'))
EXEC dbo.sp_executesql @statement = N'create view [v_databaseFileSizeLog_all] as
	select ukey,ymd,isLog,size,dbname,fileName,objectname,serverName
	from Notification..databaseFileSizeLog'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[v_drivespaceLog_all]'))
EXEC dbo.sp_executesql @statement = N'create view [v_drivespaceLog_all] as
	select ukey,ymd,driveSpace,driveLetter,serverName
	from Notification..drivespaceLog'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_returnShortDate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_returnShortDate] (@dToday dateTime)
returns varchar(14)
as
begin
	declare @cReturnString varchar(14)
	set @cReturnString = ''''

	if @dToday is not null and year(@dToday) > 1900
		set @cReturnString =
			right(''00'' + convert(varchar(2), datepart(month, @dToday)), 2) + ''-'' +
			right(''00'' + convert(varchar(2), datepart(day, @dToday)), 2) + ''-'' +
			right(convert(varchar(4), datepart(year, @dToday)), 2) + '' '' +
			right(''00'' + convert(varchar(2), datepart(hour, @dToday)), 2) + '':'' +
			right(''00'' + convert(varchar(2), datepart(minute, @dToday)), 2)

	return @cReturnString
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[v_notificationLog_all]'))
EXEC dbo.sp_executesql @statement = N'create view [v_notificationLog_all] as
	select isBlocking,isConfiguration,isConnectivity,isDriveSpace,isEventLog,isInstalledSoftware,isJobFailure,isLogShippingJobFailure,isLogSize,isLongRunningJob,isLongRunningProcess,isMonitorMessage,isService,message,messageSent,messageSentDate,serverName,severity,subject,ukey,ymd
	from Notification..notificationLog'
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[v_pingLog_all]'))
EXEC dbo.sp_executesql @statement = N'create view [v_pingLog_all] as
	select friendlyName,isRouterPingable,isServerPingable,isSQLPingable,routerPingResults,serverName,serverPingResults,sqlPingResults,ukey,ymd
	from Notification..pingLog'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[v_performanceLog_all]'))
EXEC dbo.sp_executesql @statement = N'create view [v_performanceLog_all] as
	select counterType,counterValue,instanceName,runStamp,ukey,ukey_counter,ukey_object,ukey_server,ymd
	from Notification..performanceLog'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[v_processLog_all]'))
EXEC dbo.sp_executesql @statement = N'create view [v_processLog_all] as
	select diskio,spid,ukey,cputime,lastBatchTime,login_time,ymd,isBlocked,isBlocker,isWild,waitTime,status,waitResource,lastWaitType,locks,login,net_address,programName,serverName,blockedBy,buffercontents,command,dbName,hostname,lastBatch,sql_handle,waitType
	from Notification..processLog'
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_databaseFileGrowthHistory]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'create procedure [pr_rpt_databaseFileGrowthHistory] (@cServerName varchar(100), @dStartDate dateTime)
as
begin

--	declare @cServerName varchar(100)
--	declare @dStartDate dateTime

--	set @cServerName = ''mssql-ny''
	set @dStartDate = isnull(@dStartDate, dateAdd(week, -1, getDate()))

	create table #sizeHistory (dbName varchar(100), objectName varchar(100), fileName varchar(500), size bigint, isLog bit, ymd dateTime,
		ukey int identity, lastSize bigint)

	insert into #sizeHistory (dbName, objectName, fileName, size, isLog, ymd)
	select dbName, objectName, fileName, size, isLog, ymd
		from databaseFileSizeLog
		where serverName = @cServerName
			and ymd >= @dStartDate
		order by dbName, objectName, ymd

	update a
		set lastSize = b.size
		from #sizeHistory a
		join #sizeHistory b on a.dbName = b.dbName
			and a.objectName = b.objectName
			and a.ukey = b.ukey + 1

	select dbName, objectName, fileName, ymd, lastSize, size as newSize, isLog
		from #sizeHistory
		where size <> lastSize

	drop table #sizeHistory

end

'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_IntToString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_IntToString] (@nNumber bigint)
returns varchar(100)
as
begin
	declare @cReturnString varchar(100)
	set @cReturnString = reverse(substring(reverse(convert(varchar(20), convert(money, @nNumber), 1)), 4, 20))

	return @cReturnString

end
-- select dbo.fn_IntToString(1234567)
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_encodeForGoogleCharts_simple]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'create function [fn_encodeForGoogleCharts_simple] (@nNumber int)
returns varchar(1)
as
begin
	declare @cReturnValue varchar(1)

	set @cReturnValue = case
		when @nNumber >= 0 and @nNumber <= 25
			then char(@nNumber + 65)
		when @nNumber >= 26 and @nNumber <= 51
			then char(@nNumber + 97 - 26)
		when @nNumber >= 52 and @nNumber <= 61
			then char(@nNumber + 48 - 52)
		when @nNumber is null
			then ''_''
		else ''_''
		end

	return @cReturnValue
end
'
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_makeTableFromList]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'create   function [fn_makeTableFromList] (@cList varchar(8000), @cDelimiter varchar(1))
returns @results table (ukey int identity, listItem varchar(500))
as
begin
	declare @cString varchar(500)
	declare @nDelimiterFound int

	while len(@cList) > 0
	begin
		set @nDelimiterFound = charindex(@cDelimiter, @cList)

		if @nDelimiterFound > 0
		begin
			set @cString = left(@cList, charindex(@cDelimiter, @cList) - 1)
			set @cList = substring(@cList, charindex(@cDelimiter, @cList)+1, 8000)
		end
		else
		begin
			set @cString = @cList
			set @cList = ''''
		end

		if @nDelimiterFound > 0 or len(@cString) > 0
			insert into @results (listItem) values (rtrim(ltrim(@cString)))
		else
			set @cList = ''''
	end

	return
end
-- select * from dbo.fn_makeTableFromList(''beginFoodStmp|0.00|/beginFoodStmp|/closeCashier|trans type="closeCashier"|trHeader|cashier sysid="3" empNum="3" posNum="102" period="7" drawer="1"|khalif|/cashier|posNum|102|/posNum|/trHeader|cashier sysid="3" empNum="3" posNum="102" period="7" drawer="1"|khalif|/cashier|posNum|102|/posNum|cOpenTime|2006-10-20T11:56:00-04:00|/cOpenTime|cCloseTime|2006-10-20T12:02:22-04:00|/cCloseTime|beginTicket|0|/beginTicket|endTicket|0|/endTicket|cashierPeriod|7|/cashierPeriod|ticketCount|0|/ticketCount|beginCash|0.00|/beginCash|beginFoodStmp|0.00|/beginFoodStmp|/trans|printCashier|cashier sysid="3" empNum="3" posNum="102" period="7"|khalif|/cashier|posNum|102|/posNum|cashierPeriod|7|/cashierPeriod|cCloseTime|2006-10-20T12:02:22-04:00|/cCloseTime|cReportTime|2006-10-20T12:02:32-04:00|/cReportTime|drawerAmounts|drawerAmount|paymentName mop="1" cat="0"|CASH|/paymentName|ECRAmount locale="USD"|0.00|/ECRAmount|actualAmount locale="USD"|0.00|/actualAmount|/drawerAmount|/drawerAmounts|/printCashier|trans type="printCashier"|cashier sysid="3" empNum="3" posNum="102" period="7"|khalif|/cashier|posNum|102|/posNum|cashierPeriod|7|/cashierPeriod|cCloseTime|2006-10-20T12:02:22-04:00|/cCloseTime|cReportTime|2006-10-20T12:02:32-04:00|/cReportTime|drawerAmounts|drawerAmount|paymentName mop="1" cat="0"|CASH|/paymentName|ECRAmount locale="USD"|0.00|/ECRAmount|actualAmount locale="USD"|0.00|/actualAmount|/drawerAmount|/drawerAmounts|/trans|trans type="sale" recalled="false"|trHeader|termMsgSN type="FINANCIAL" term="103"|31937|/termMsgSN|trTickNum|posNum|103|/posNum|trSeq|1031941|/trSeq|/trTickNum|period level="0" name="HOUR" seq="12"/|period level="1" name="SHIFT" seq="39"/|period level="2" name="DAILY" seq="39"/|date|2006-10-20T12:01:38-04:00|/date|duration|55|/duration|till|1|/till|cashier sysid="10" empNum="2046" posNum="103" period="22" drawer="1"|DAP|/cashier|storeNumber|RT053|/storeNumber|/trHeader|trValue|trTotNoTax|66.48|/trTotNoTax|trTotWTax|69.39|/trTotWTax|trTotTax|2.91|/trTotTax|trTax|taxAmts|taxAmt sysid="3" cat="Regular Sa"|48.48|/taxAmt|taxRate sysid="3" cat="Regular Sa"|6.000|/taxRate|taxNet sysid="3" cat="Regular Sa"|2.91|/taxNet|taxAttribute sysid="3" cat="Regular Sa"|0|/taxAttribute|/taxAmts|/trTax|trCurrTot locale="USD"|69.39|/trCurrTot|trSTotalizer|69.39|/trSTotalizer|trGTotalizer|69.39|/trGTotalizer|custDOB|101057|/custDOB|/trValue|trLines|trLine type="postFuel"|trlTaxes reverse="0"/|trlFlags|trlUpdDepCust/|trlCatCust/|trlFuelSale/|/trlFlags|trlDept type="fuel" number="10"|FUEL|/trlDept|trlCat number="10"|FUEL|/trlCat|trlNetwCode|13|/trlNetwCode|trlQty|7.900|/trlQty|trlSign|1.00|/trlSign|trlUnitPrice|2.279|/trlUnitPrice|trlLineTot|18.00|/trlLineTot|trlFuel type="norm"|trlFuelSeq|2|/trlFuelSeq|fuelPosition|5|/fuelPosition|trlFuelDepst|0.00|/trlFuelDepst|fuelProd sysid="3"|PREM|/fuelProd|fuelSvcMode sysid="1"|SELF|/fuelSvcMode|fuelMOP sysid="1"|CASH|/fuelMOP|fuelVolume|7.900|/fuelVolume|/trlFuel|trlDesc|PREM CA #05|/trlDesc|/trLine|trLine type="plu"|trlTaxes reverse="0"|trlTax sysid="3" cat="Regular Sa"|25.49|/trlTax|trlRate sysid="3" cat="Regular Sa"|6.000|/trlRate|/trlTaxes|trlFlags|trlBdayVerif/|trlPLU/|trlUpdPluCust/|trlUpdDepCust/|trlCatCust/|/trlFlags|trlDept type="norm" number="11"|CIGARETTES|/trlDept|trlCat number="2"|BEER|/trlCat|trlNetwCode|7|/trlNetwCode|trlQty|1|/trlQty|trlSign|1.00|/trlSign|trlSellUnit|1.000|/trlSellUnit|trlUnitPrice|25.49|/trlUnitPrice|trlLineTot|25.49|/trlLineTot|trlDesc|Marl Lt Kngb|/trlDesc|trlUPC|00028200106902|/trlUPC|trlModifier|000|/trlModifier|trlUPCEntry type="scanned"/|/trLine|trLine type="plu"|trlTaxes reverse="0"|trlTax sysid="3" cat="Regular Sa"|22.99|/trlTax|trlRate sysid="3" cat="Regular Sa"|6.000|/trlRate|/trlTaxes|trlFlags|trlBdayVerif/|trlPLU/|trlUpdPluCust/|/trlFlags|trlDept type="norm" number="11"|CIGARETTES|/trlDept|trlCat number="2"|BEER|/trlCat|trlNetwCode|7|/trlNetwCode|trlQty|1|/trlQty|trlSign|1.00|/trlSign|trlSellUnit|1.000|/trlSellUnit|trlUnitPrice|22.99|/trlUnitPrice|trlLineTot|22.99|/trlLineTot|trlDesc|Wins Lt 100s|/trlDesc|trlUPC|00012300113137|/trlUPC|trlModifier|000|/trlModifier|trlUPCEntry type="scanned"/|/trLine|/trLines|trPaylines|trPayline type="sale" sysid="1" locale="DOLLAR"|trpPaycode mop="11" cat="7"|COUPON|/trpPaycode|trpAmt|3.00|/trpAmt|trpCouponEntryMethod|MANUAL|/trpCouponEntryMethod|/trPayline|trPayline type="sale" sysid="1" locale="DOLLAR"|trpPaycode mop="1" cat="0"|CASH|/trpPaycode|trpAmt|66.39|/trpAmt|/trPayline|/trPaylines|/trans|trans type="sale" recalled="false"|trHeader|termMsgSN type="FINANCIAL" term="103"|31938|/termMsgSN|trTickNum|posNum|103|/posNum|trSeq|1031942|/trSeq|/trTickNum|period level="0" name="HOUR" seq="12"/|period level="1" name="SHIFT" seq="39"/|period level="2" name="DAILY" seq="39"/|date|2006-10-20T12:02:47-04:00|/date|duration|2|/duration|till|1|/till|cashier sysid="10" empNum="2046" posNum="103" period="22" drawer="1"|DAP|/cashier|storeNumber|RT053|/storeNumber|/trHeader|trValue|trTotNoTax|10.00|/trTotNoTax|trTotWTax|10.00|/trTotWTax|trTotTax|0.00|/trTotTax|trTax/|trCurrTot locale="USD"|10.00|/trCurrTot|trSTotalizer|10.00|/trSTotalizer|trGTotalizer|10.00|/trGTotalizer|/trValue|trLines|trLine type="preFuel"|trlTaxes reverse="0"/|trlFlags|trlUpdDepCust/|trlCatCust/|trlFuelSale/|/trlFlags|trlDept type="fuel" number="9999"|FUEL DEPOSIT|/trlDept|trlCat number="9999"|FUEL DEPOSIT|/trlCat|trlNetwCode|32|/trlNetwCode|trlQty|1|/trlQty|trlSign|1.00|/trlSign|trlUnitPrice|0.000|/trlUnitPrice|trlLineTot|10.00|/trlLineTot|trlDesc|PREPAY CA #06|/trlDesc|/trLine|/trLines|trPaylines|trPayline type="sale" sysid="1" locale="DOLLAR"|trpPaycode mop="1" cat="0"|CASH|/trpPaycode|trpAmt|10.00|/trpAmt|/trPayline|/trPaylines|/trans|trans type="sale" recalled="false"'', ''|'')
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_occurs]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE function [fn_occurs] (@cStringToFind varchar(500), @cSource varchar(500))
returns int
as
begin
	declare @nOccurs int
	declare @nCounter int
	declare @nStringLength int
	set @nCounter = 1
	set @nOccurs = 0
	set @nStringLength = len(@cStringToFind)
	if @cStringToFind = space(1)
		set @nStringLength = 1

	while (@nCounter - 1 + @nStringLength) < (len(@cSource) + 1)
	begin
		if substring(@cSource, @nCounter, @nStringLength) = @cStringToFind
			set @nOccurs = @nOccurs + 1

		set @nCounter = @nCounter + 1
	end

	return @nOccurs
end
-- select dbo.fn_occurs('' '', ''test test'')
'
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_padl]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'create function [fn_padl] (@cString varchar(200), @nLength int, @cPadCharacter varchar(1))
	returns varchar(200)
as
begin
	while len(@cString) < @nLength
		set @cString = @cPadCharacter + @cString

	return @cString
end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[fn_padr]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE    function [fn_padr] (@cString varchar(200), @nLength int, @cPadCharacter varchar(1))
	returns varchar(200)
as
begin

	if @cPadCharacter = '' ''
		return @cString + space(@nLength - len(@cString))
	else
	begin
		while len(@cString) < @nLength
			set @cString = @cString + @cPadCharacter

	end

	return @cString

end
'
END
GO
