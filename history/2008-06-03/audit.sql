IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'sqlnotification')
CREATE USER [sqlnotification] FOR LOGIN [sqlnotification] WITH DEFAULT_SCHEMA=[dbo]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
