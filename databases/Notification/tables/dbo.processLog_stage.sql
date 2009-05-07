/****** Object:  Table [dbo].[processLog_stage]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[processLog_stage](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[serverName] [varchar](200) NULL,
	[spid] [int] NULL,
	[status] [varchar](100) NULL,
	[login] [varchar](100) NULL,
	[hostname] [varchar](128) NULL,
	[blockedBy] [varchar](20) NULL,
	[dbName] [varchar](128) NULL,
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
	[waitResource] [varchar](256) NULL
) ON [PRIMARY]
GO
