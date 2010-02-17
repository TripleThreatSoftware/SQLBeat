USE [Configuration]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_runningProcessHistory]    Script Date: 02/17/2010 14:53:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_runningProcessHistory 35, null, null --'2008-01-11 17:00:00.000', '2008-01-12 01:00:00.000'
-- select * from notification..dm_servers where serverName = 'uatmssql02'

ALTER procedure [dbo].[pr_rpt_runningProcessHistory] (@nUkeyServer int, @dStartDate dateTime, @dEndDate dateTime)
as
begin

	declare @cServerName varchar(100)
	set @cServerName = (select top 1 serverName from notification..dm_servers where ukey = @nUkeyServer)

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -24, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())


	select a.*, b.serverName, a.IOWriteBytesPersecond as IOWriteBytesPersec, a.IOReadBytesPersecond as IOReadBytesPersec

		from runningProcessLog a (nolock)
		join notification..dm_servers b (nolock) on a.ukey_server = b.ukey
			and b.serverName = @cServerName
		where a.ukey_server = @nUkeyServer
			and a.ymd >= @dStartDate
			and a.ymd <= @dEndDate
		order by serverName, processName, ymd, instance

end
