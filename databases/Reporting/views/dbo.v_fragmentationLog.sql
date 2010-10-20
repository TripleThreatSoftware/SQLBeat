/****** Object:  View [dbo].[v_fragmentationLog]    Script Date: 10/20/2010 11:53:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_fragmentationLog] as select * from notification.dbo.fragmentationLog (nolock)
GO
