create procedure [dbo].[pr_returnReportType] (@nUkeyReport int)
as
begin
	select top 1 reportType, reportName
		from reportMetaData
		where ukey = @nUkeyreport
end
GO
