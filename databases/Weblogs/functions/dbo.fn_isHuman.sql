/****** Object:  UserDefinedFunction [dbo].[fn_isHuman]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   function [dbo].[fn_isHuman](@cMachineType varchar(500))
returns bit
as
begin
	declare @lReturnValue bit
	set @lReturnValue = 1

	if @cMachineType like '%bot%'
		or @cMachineType like '%spider%'
		or @cMachineType like '%linkwalker%'
		or @cMachineType like '%archiver%'
		or @cMachineType like '%crawl%'
		or @cMachineType like '%seeker%'
		or @cMachineType like '%bigbrother%'
		or @cMachineType like '%gomezagent%'
		or @cMachineType like '%index%'
		or @cMachineType like '%slurp%'
		or @cMachineType like '%ask.com%'
		or @cMachineType like '%ocelli%'
		or @cMachineType like '%wget%'
		or @cMachineType like '%hobbit%'
		or @cMachineType like '%python%'
		or @cMachineType like '%curl%'
		or @cMachineType like '%search%'
		or @cMachineType like '%java%'
		or @cMachineType like '%RPT-HTTPClient%'
		or @cMachineType like '%internal+zero-knowledge+agent%'
		or @cMachineType = ''
		or @cMachineType = '-'
		set @lReturnValue = 0

	return @lReturnValue
end
-- select dbo.fn_isHuman('Mozilla')
GO
