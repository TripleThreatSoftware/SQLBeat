-- ================================================================================================
-- Configuration.dbo.dm_serverCounters
--
-- A dimension table which tells SQLBeat which Counters to query for each configured Server.
-- ================================================================================================
/****** Object:  Table [dbo].[dm_serverCounters]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dm_serverCounters](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_server] [int] NOT NULL,
	[ukey_counter] [bigint] NOT NULL,
	[lastCheck] [datetime] NULL,
	[checkMinuteInterval] [int] NULL,
	[isEnabled] [bit] NULL,
 CONSTRAINT [PK_dm_serverCounters] PRIMARY KEY NONCLUSTERED
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [ix_dm_serverCounters_ukeyServer_ukeyCounter]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_dm_serverCounters_ukeyServer_ukeyCounter] ON [dbo].[dm_serverCounters]
(
	[ukey_server] ASC,
	[ukey_counter] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[dm_serverCounters] ADD  DEFAULT ((1)) FOR [isEnabled]
GO
