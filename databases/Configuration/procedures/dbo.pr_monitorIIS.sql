/****** Object:  StoredProcedure [dbo].[pr_monitorIIS]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_monitorIIS 'appweb49'
CREATE procedure [dbo].[pr_monitorIIS] (@cServerName varchar(500))
as
begin
	-- declare @cServerName varchar(500) = 'appweb34'

	set nocount on

	declare @cQuery varchar(4000)
	declare @cUserName varchar(100) = (select top 1 wmiUserName from notification..dm_servers where servername = @cServerName)
	declare @cPassword varchar(100) = (select top 1 wmiPassword from notification..dm_servers where servername = @cServerName)

	if object_id('tempdb..#results') is not null
		drop table #results

	create table #results (counterName varchar(500), objectName varchar(500), keyName varchar(500), keyValue varchar(max))

	--set @cQuery = 'select * from Win32_PerfFormattedData_APPPOOLCountersProvider_APPPOOLWAS where name = ""AppSecure""'
	--set @cQuery = 'select * from Win32_PerfFormattedData_W3SVC_WebService where name = ""AppSecure""'

	-- ********************************************************************************************************************************************
	-- ********************************************************************************************************************************************
	set @cQuery = 'select * from Win32_PerfFormattedData_NETDataProviderforSqlServer_NETDataProviderforSqlServer'

	exec pr_runWMIQuery @cServerName, @cUserName, @cPassword, @cQuery

	update #results set counterName = 'Win32_PerfFormattedData_NETDataProviderforSqlServer_NETDataProviderforSqlServer' where counterName is null

	-- ********************************************************************************************************************************************
	-- ********************************************************************************************************************************************
	set @cQuery = 'select * from Win32_PerfFormattedData_APPPOOLCountersProvider_APPPOOLWAS'

	exec pr_runWMIQuery @cServerName, @cUserName, @cPassword, @cQuery

	update #results set counterName = 'Win32_PerfFormattedData_APPPOOLCountersProvider_APPPOOLWAS' where counterName is null

	-- ********************************************************************************************************************************************
	-- ********************************************************************************************************************************************
	set @cQuery = 'select * from Win32_PerfFormattedData_W3SVC_WebService'

	exec pr_runWMIQuery @cServerName, @cUserName, @cPassword, @cQuery

	update #results set counterName = 'Win32_PerfFormattedData_W3SVC_WebService' where counterName is null

	insert into iisSnapshot (serverName, counterName, objectName, keyName, keyValue)
	select @cServerName, counterName, objectName, keyName, keyValue from #results
end

--alter table iisSnapshot add servername varchar(100)
--exec sp_rename 'tmp_iis_snapshot', 'iisSnapshot'
--select top 100 * from #results
--select * into tmp_iis_snapshot from #results
--select top 100 * from applicationPoolLog order by ymd desc

--select *
--	from tmp_iis_snapshot
--	where objectName like '%Secure%'

--select *
--	from tmp_iis_snapshot
--	where counterName like '%Win32_PerfFormattedData_NETDataProviderforSqlServer_NETDataProviderforSqlServer%'
GO
