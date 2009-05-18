/****** Object:  Table [dbo].[deepSQLStats_memoryAllocation]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[deepSQLStats_memoryAllocation](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NULL,
	[serverName] [varchar](100) NULL,
	[memoryType] [varchar](100) NULL,
	[allocated] [bigint] NULL,
	[warning] [varchar](500) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [ix_deepSQLStatsMemoryAllocation_ukey_ukeyServer_ymd] ON [dbo].[deepSQLStats_memoryAllocation]
(
	[ukey] ASC,
	[ukey_server] ASC,
	[ymd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
