-- ================================================================================================
-- Notification.dbo.hist_partitionTableDaily
--
-- This is a log table for pr_partitionTableDaily, which is responsible for maintaining the
-- partitioned tables in the montly datamarts
-- ================================================================================================
/****** Object:  Table [dbo].[hist_partitionTableDaily]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[hist_partitionTableDaily](
	[ymd] [datetime] NULL,
	[stepName] [varchar](200) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[hist_partitionTableDaily] ADD  DEFAULT (getdate()) FOR [ymd]
GO
