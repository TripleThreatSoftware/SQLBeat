/****** Object:  StoredProcedure [dbo].[pr_returnReportFieldFound]    Script Date: 10/20/2010 11:53:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[pr_returnReportFieldFound] @level1 varchar(25), @level2 varchar(25)=null, @level3 varchar(25)=null,
			@level4 varchar(25)=null, @level5 varchar(25)=null
AS
BEGIN
	declare @output varchar(25)
	--check to see if level 6 exists with conditions
	if @level5 is not Null
		begin
			if exists (select distinct level6 from [Reporting].[dbo].[reportMetaData] where level1 = @level1 and level2 = @level2 and  level3=@level3
																						and level4 = @level4 and level5 = @level5 and level6 is not Null)
				set @output = 'found'
			else
				set @output = 'not found'
		end
	--check to see if level 5 exists with conditions
	else if @level4 is not Null
		begin
			if exists (select distinct level5 from [Reporting].[dbo].[reportMetaData] where level1 = @level1 and level2 = @level2 and  level3=@level3
																						and level4 = @level4 and level5 is not Null )
				set @output = 'found'
			else
				set @output = 'not found'
		end
	--check to see if level 4 exists with conditions
	else if @level3 is not Null
		begin
			if exists (select distinct level4 from [Reporting].[dbo].[reportMetaData] where level1 = @level1 and level2 = @level2 and  level3=@level3 and level4 is not Null)
				set @output = 'found'
			else
				set @output = 'not found'
		end
	--check to see if level 3 exists with conditions
	else if @level2 is not Null
		begin
			if exists (select distinct level3 from [Reporting].[dbo].[reportMetaData] where level1 = @level1 and level2 = @level2 and level3 is not Null)
				set @output = 'found'
			else
				set @output = 'not found'
		end
	--check to see if level 2 exists with conditions
	else
		begin
			if exists (select distinct level2 from [Reporting].[dbo].[reportMetaData] where level1 = @level1 and level2 is not Null)
				set @output = 'found'
			else
				set @output = 'not found'
		end

	select @output as output
END
GO
