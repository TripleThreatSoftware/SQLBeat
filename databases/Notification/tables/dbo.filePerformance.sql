/****** Object:  Table [dbo].[filePerformance]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[filePerformance](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[ukey_server] [int] NULL,
	[serverName] [varchar](100) NULL,
	[databaseName] [varchar](100) NULL,
	[fileName] [varchar](500) NULL,
	[file_id] [bigint] NULL,
	[sample_ms] [bigint] NULL,
	[serverStartDate] [datetime] NULL,
	[num_of_reads] [bigint] NOT NULL,
	[num_of_bytes_read] [bigint] NOT NULL,
	[io_stall_read_ms] [bigint] NOT NULL,
	[num_of_writes] [bigint] NOT NULL,
	[num_of_bytes_written] [bigint] NOT NULL,
	[io_stall_write_ms] [bigint] NOT NULL,
	[io_stall] [bigint] NOT NULL,
	[size_on_disk_bytes] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[filePerformance] ADD  DEFAULT (getdate()) FOR [ymd]
GO
