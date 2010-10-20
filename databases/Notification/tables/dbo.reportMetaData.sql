SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[reportMetaData]    Script Date: 10/20/2010 11:53:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[reportMetaData](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[level1] [varchar](500) NULL,
	[level2] [varchar](500) NULL,
	[level3] [varchar](500) NULL,
	[level4] [varchar](500) NULL,
	[level5] [varchar](500) NULL,
	[level6] [varchar](500) NULL,
	[counterName] [varchar](500) NULL,
	[counterDescription] [varchar](8000) NULL,
	[tableName] [varchar](200) NULL,
	[dateField] [varchar](100) NULL,
	[dataField] [varchar](100) NULL,
	[whereClause] [varchar](2000) NULL,
	[storedProcedureName] [varchar](500) NULL
) ON [PRIMARY]
GO
