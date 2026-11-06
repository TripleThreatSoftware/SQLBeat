/****** Object:  StoredProcedure [dbo].[pr_returnServerTypes]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_returnServerTypes]
as
begin
	declare @results table (serverType varchar(100))

	insert into @results (serverType) values ('SQL Server')
	insert into @results (serverType) values ('IIS Webserver')

	select * from @results
end
GO
