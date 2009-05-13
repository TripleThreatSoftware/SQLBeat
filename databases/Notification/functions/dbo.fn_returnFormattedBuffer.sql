USE [Notification]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_returnFormattedBuffer]    Script Date: 05/13/2009 19:11:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [dbo].[fn_returnFormattedBuffer] (@cBuffer varchar(8000))
returns varchar(8000)
as
begin
	declare @cReturnString varchar(8000)

	set @cReturnString = replace(replace(replace(replace(
			left(case
				when @cBuffer like '%sp_%' then 'System Stored Proc'
				when @cBuffer like '%updateprocessingtime%' then 'UPT'
				when @cBuffer like '%fetch%cursor%' then 'CURSOR'
				when @cBuffer like '%Transactions_PurgeByDays%' then 'Daily Purge'
				else @cBuffer end, 500),
			char(13), '<br>'), '|', ''), ';1', ''), 'NETWORKIO', '')

	return @cReturnString
end
