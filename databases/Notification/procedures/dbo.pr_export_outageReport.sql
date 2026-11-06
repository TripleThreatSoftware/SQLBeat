/****** Object:  StoredProcedure [dbo].[pr_export_outageReport]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_export_outageReport]
as
begin

	if exists (select top 1 [name] from sysobjects where [name] = 'tmp_export_outageReport')
		drop table tmp_export_outageReport

	create table tmp_export_outageReport (ukey int, groupName varchar(200), serverName varchar(500), eventDetail varchar(8000), startDate dateTime, endDate dateTime)

	insert into tmp_export_outageReport
	exec pr_rpt_weeklyTailReport

	declare @cSQLString nvarchar(4000)

	set @cSQLString = 'bcp "select groupName, serverName, eventDetail, startDate, endDate from notification.dbo.tmp_export_outageReport" queryout c:\inetpub\wwwroot\outageReport.txt -c -T'
	exec master..xp_cmdshell @cSQLString

	if exists (select top 1 [name] from sysobjects where [name] = 'tmp_export_outageReport')
		drop table tmp_export_outageReport
end
GO
