/****** Object:  Table [dbo].[dm_version]    Script Date: 11/6/2026 9:48:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_version](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[version] [varchar](50) NULL,
	[dateAdded] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_version] ADD  DEFAULT (getdate()) FOR [dateAdded]
GO
