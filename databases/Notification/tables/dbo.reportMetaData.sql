CREATE TABLE [dbo].[reportMetaData](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_parent] [int] NULL,
	[reportName] [varchar](200) NULL,
	reportGroup varchar(100),
	[storedProcedureName] [varchar](200) NULL,
	[reportType] [varchar](100) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[reportMetaData] ADD  DEFAULT (getdate()) FOR [ymd]
GO
