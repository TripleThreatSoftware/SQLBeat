/****** Object:  View [dbo].[v_tableSizeLog]    Script Date: 10/20/2010 11:53:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_tableSizeLog] as select * from notification.dbo.tableSizeLog (nolock)
GO
