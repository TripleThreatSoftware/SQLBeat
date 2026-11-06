/****** Object:  UserDefinedFunction [dbo].[fn_returnApacheRow_CLR]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[fn_returnApacheRow_CLR](@cWideString [nvarchar](max), @cFileName [nvarchar](max), @cFilePath [nvarchar](max))
RETURNS  TABLE (
	[Hostname] [nvarchar](500) NULL,
	[ClientIP] [nvarchar](500) NULL,
	[String1] [nvarchar](500) NULL,
	[Ymdstring] [nvarchar](500) NULL,
	[Ymd] [datetime] NULL,
	[HttpMethod] [nvarchar](max) NULL,
	[HttpResponse] [int] NULL,
	[Bytes] [int] NULL,
	[Referer1] [nvarchar](max) NULL,
	[Useragent] [nvarchar](max) NULL,
	[RequestID] [nvarchar](100) NULL,
	[Referer2] [nvarchar](max) NULL,
	[Logfile] [nvarchar](max) NULL,
	[Number2] [int] NULL,
	[Number3] [nvarchar](50) NULL,
	[MD5hash] [nvarchar](100) NULL,
	[String2] [nvarchar](500) NULL,
	[Httprequest] [nvarchar](max) NULL,
	[ErrorType] [nvarchar](500) NULL,
	[PID] [nvarchar](100) NULL,
	[ErrorMessage] [nvarchar](max) NULL,
	[String3] [nvarchar](500) NULL
) WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [ApacheLogParser].[ApacheLogParser].[ParseApacheLogLine]
GO
