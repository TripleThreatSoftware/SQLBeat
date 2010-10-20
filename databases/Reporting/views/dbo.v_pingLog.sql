/****** Object:  View [dbo].[v_pingLog]    Script Date: 10/20/2010 11:53:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_pingLog] as select * from notification.dbo.pingLog (nolock)
GO
