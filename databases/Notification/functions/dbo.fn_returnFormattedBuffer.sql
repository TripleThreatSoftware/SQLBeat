SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [dbo].[fn_returnFormattedBuffer] (@cBuffer varchar(8000))
returns varchar(8000)
as
begin
	declare @cReturnString varchar(8000)

	set @cReturnString = replace(replace(replace(replace(replace(replace(replace(
			left(case
--				when @cBuffer like '%sp_%' then 'System Stored Proc'
				when @cBuffer like '%updateprocessingtime%' then 'UPT'
				when @cBuffer like '%fetch%cursor%' then 'CURSOR'
				when @cBuffer like '%Transactions_PurgeByDays%' then 'Daily Purge'
				else @cBuffer end, 500),
			char(13), '<br>'), '|', ''), ';1', ''), 'NETWORKIO', ''), 'sys.', ''), 'sp_reset_connection', ''), char(0), '')



	if right(@cReturnString, 4) = '<br>'
		set @cReturnString = left(@cReturnString, len(@cReturnString) - 4)

	return @cReturnString
end
