-- ================================================================================================
-- Configuration.dbo.runs_data
--
-- Holds a record of each WMI query run results. This table is partitioned to v_runs_data_all.
-- ================================================================================================
/****** Object:  Table [dbo].[runs_data]    Script Date: 11/6/2026 9:47:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[runs_data](
	[ukey] [bigint] NOT NULL,
	[ukey_server] [bigint] NULL,
	[ukey_counter] [bigint] NULL,
	[keyValue] [varchar](1000) NULL,
	[ukey_run] [bigint] NULL,
	[instance] [int] NULL,
	[ukey_keyName] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Index [ix_runs_data_compound]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE CLUSTERED INDEX [ix_runs_data_compound] ON [dbo].[runs_data]
(
	[ukey_run] ASC,
	[ukey_server] ASC,
	[ukey_counter] ASC,
	[instance] ASC,
	[ukey_keyName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_runs_data_ukeyServer]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_runs_data_ukeyServer] ON [dbo].[runs_data]
(
	[ukey_server] ASC,
	[ukey_run] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 60, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [ix_runsData_server_counter_run]    Script Date: 11/6/2026 9:47:51 AM ******/
CREATE NONCLUSTERED INDEX [ix_runsData_server_counter_run] ON [dbo].[runs_data]
(
	[ukey_server] ASC,
	[ukey_counter] ASC,
	[ukey_run] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
