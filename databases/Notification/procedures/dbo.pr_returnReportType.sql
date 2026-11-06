/****** Object:  StoredProcedure [dbo].[pr_returnReportType]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_returnReportType] (@nUkeyReport int)
as
begin
	select top 1 reportType, reportName
		from reportMetaData
		where ukey = @nUkeyreport
end
GO
