/****** Object:  UserDefinedFunction [dbo].[fn_runStampToDate]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select dbo.fn_runStampToDate(20090401110601747)

create function [dbo].[fn_runStampToDate] (@nRunStamp bigint)
returns dateTime
as
begin
	declare @cReturnString varchar(20)

	set @cReturnString =
		substring(convert(varchar(50), @nRunStamp), 1, 4) + '-' +
		substring(convert(varchar(50), @nRunStamp), 5, 2) + '-' +
		substring(convert(varchar(50), @nRunStamp), 7, 2) + ' ' +
		substring(convert(varchar(50), @nRunStamp), 9, 2) + ':' +
		substring(convert(varchar(50), @nRunStamp), 11, 2)

	set @cReturnString = isnull(@cReturnString, '')

	return @cReturnString
end
GO
