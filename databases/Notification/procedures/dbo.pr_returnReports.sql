/****** Object:  StoredProcedure [dbo].[pr_returnReports]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_returnReports null, null, 'SQL'
CREATE procedure [dbo].[pr_returnReports] (@nDepth int = 0, @nUkeyParent int = 0, @cServerName varchar(100) = '', @cReportGroup varchar(100) = '')
as
begin
	declare @nUkey int
	declare @cReportName varchar(200)

	set @nDepth = isnull(@nDepth, 0)
	set @nUkeyParent = isnull(@nUkeyParent, 0)

	if @nDepth = 0
		create table #results (ukey int identity, ukey_report int, depth int, reportName varchar(200), storedProcedureName varchar(500))

	set @nDepth = @nDepth + 1

	set @nUkey = 0
	set @cReportName = ''

	while exists (select top 1 ukey from reportMetaData where isnull(reportGroup, '') = isnull(@cReportGroup, '') and reportName > @cReportName and isnull(ukey_parent, 0) = @nUkeyParent and ukey in (select distinct isnull(ukey_parent, 0) from reportMetaData))
	begin
		select top 1
			@nUkey = ukey,
			@cReportName = reportName
			from reportMetaData
			where reportName > @cReportName
				and isnull(ukey_parent, 0) = @nUkeyParent
				and ukey in (select distinct isnull(ukey_parent, 0) from reportMetaData)
				and isnull(reportGroup, '') = isnull(@cReportGroup, '')
			order by reportName

		insert into #results (ukey_report, depth, reportName, storedProcedureName)
		select ukey, @nDepth, reportName, storedProcedureName
			from reportMetaData
			where ukey = @nUkey

		exec pr_returnReports @nDepth, @nUkey, @cServerName, @cReportGroup
	end

	set @cReportName = ''

	while exists (select top 1 ukey from reportMetaData where isnull(reportGroup, '') = isnull(@cReportGroup, '') and reportName > @cReportName and isnull(ukey_parent, 0) = @nUkeyParent and ukey not in (select distinct isnull(ukey_parent, 0) from reportMetaData))
	begin
		select top 1
			@nUkey = ukey,
			@cReportName = reportName
			from reportMetaData
			where reportName > @cReportName
				and isnull(ukey_parent, 0) = @nUkeyParent
				and ukey not in (select distinct isnull(ukey_parent, 0) from reportMetaData)
				and isnull(reportGroup, '') = isnull(@cReportGroup, '')
			order by reportName

		insert into #results (ukey_report, depth, reportName, storedProcedureName)
		select ukey, @nDepth, reportName, storedProcedureName
			from reportMetaData
			where ukey = @nUkey
	end


	if @nDepth = 1
	begin
		select *,
			replicate('&nbsp;', (depth-1)*2) as spacing,
			case when isnull(storedProcedureName, '') = '' then '<b>' + reportName + '</b>' else '<a href="reports.aspx?serverName=' + @cServerName + '&reportGroup=' + @cReportGroup + '&ukey_report=' + convert(varchar(20), ukey_report) + '">' + reportName + '</a>' end as displayString
			from #results
		drop table #results
	end
end
GO
