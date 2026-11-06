-- ================================================================================================
-- Notification.dbo.eventLog_stage_hist
--
-- This is a log table for the process of staging records from eventLog_stage into eventLog
-- ================================================================================================
/****** Object:  Table [dbo].[eventLog_stage_hist]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[eventLog_stage_hist](
	[ukey_group] [int] NULL,
	[ymd] [datetime] NULL,
	[step] [varchar](200) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[eventLog_stage_hist] ADD  DEFAULT (getdate()) FOR [ymd]
GO
