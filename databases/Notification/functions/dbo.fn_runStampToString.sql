/****** Object:  UserDefinedFunction [dbo].[fn_runStampToString]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select dbo.fn_runstampToString(20090401110601747)

create function [dbo].[fn_runStampToString] (@nRunStamp bigint)
returns varchar(20)
as
begin
	declare @cReturnString varchar(20)

	set @cReturnString =
		substring(convert(varchar(50), @nRunStamp), 1, 4) + '-' +
		substring(convert(varchar(50), @nRunStamp), 5, 2) + '-' +
		substring(convert(varchar(50), @nRunStamp), 7, 2) + ' ' +
		substring(convert(varchar(50), @nRunStamp), 9, 2) + ':' +
		substring(convert(varchar(50), @nRunStamp), 11, 2)

	return @cReturnString
end
GO
