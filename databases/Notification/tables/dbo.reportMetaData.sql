/****** Object:  Table [dbo].[reportMetaData]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[reportMetaData](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_parent] [int] NULL,
	[reportName] [varchar](200) NULL,
	[reportGroup] [varchar](100) NULL,
	[storedProcedureName] [varchar](200) NULL,
	[reportType] [varchar](100) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[reportMetaData] ADD  DEFAULT (getdate()) FOR [ymd]
GO
