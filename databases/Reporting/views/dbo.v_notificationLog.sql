SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[v_notificationLog]    Script Date: 10/20/2010 11:53:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_notificationLog] as select * from notification.dbo.notificationLog (nolock)
GO
