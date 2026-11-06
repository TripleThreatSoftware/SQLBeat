/****** Object:  Table [dbo].[securityEventIds]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[securityEventIds](
	[ukey] [bigint] IDENTITY(1,1) NOT NULL,
	[eventID] [int] NULL,
	[severity] [int] NULL,
	[enabled] [int] NULL,
	[shortdescription] [varchar](2000) NULL,
	[ymd_inserted] [datetime] NULL,
	[ymd_modified] [datetime] NULL,
	[whoDidIt] [sysname] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[securityEventIds] ADD  DEFAULT ((1)) FOR [enabled]
GO
ALTER TABLE [dbo].[securityEventIds] ADD  DEFAULT (getdate()) FOR [ymd_inserted]
GO
ALTER TABLE [dbo].[securityEventIds] ADD  DEFAULT (getdate()) FOR [ymd_modified]
GO
ALTER TABLE [dbo].[securityEventIds] ADD  DEFAULT (suser_sname()) FOR [whoDidIt]
GO
ALTER TABLE [dbo].[securityEventIds] ENABLE TRIGGER [trg_securityEventIds_updated]
GO
