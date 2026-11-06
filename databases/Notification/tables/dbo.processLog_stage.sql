-- ================================================================================================
-- Notification.dbo.processLog_stage
--
-- This table is used by pr_examineServer to stage and update information about observed SQL
-- processes
-- ================================================================================================
/****** Object:  Table [dbo].[processLog_stage]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[processLog_stage](
	[ukey] [int] IDENTITY(1,1) NOT NULL,	-- An internally used incrementing identity counter; uniquely identifies this row, and may be used as a Foreign Key.
	[serverName] [varchar](200) NULL,	-- The server name
	[spid] [int] NULL,
	[status] [varchar](100) NULL,
	[login] [varchar](100) NULL,
	[hostname] [varchar](128) NULL,
	[blockedBy] [varchar](20) NULL,
	[dbName] [varchar](128) NULL,	-- The database name
	[command] [varchar](100) NULL,
	[cputime] [int] NULL,
	[diskio] [int] NULL,
	[lastBatch] [varchar](100) NULL,
	[programName] [varchar](100) NULL,
	[buffercontents] [varchar](3000) NULL,
	[lastBatchTime] [datetime] NULL,
	[locks] [varchar](4000) NULL,
	[isBlocked] [bit] NULL,
	[isBlocker] [bit] NULL,
	[isWild] [bit] NULL,
	[sql_handle] [binary](20) NULL,
	[ymd] [datetime] NULL,
	[lastWaitType] [varchar](32) NULL,
	[login_time] [datetime] NULL,
	[net_address] [varchar](12) NULL,
	[waitType] [binary](2) NULL,
	[waitTime] [bigint] NULL,
	[waitResource] [varchar](256) NULL,
	[pagesInMemory] [bigint] NULL,
	[diskReads] [bigint] NULL,
	[diskWrites] [bigint] NULL,
	[logicalReads] [bigint] NULL,
	[numLocks] [int] NULL
) ON [PRIMARY]
GO
