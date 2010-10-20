/****** Object:  View [dbo].[v_databaseFileSizeLog]    Script Date: 10/20/2010 11:53:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_databaseFileSizeLog] as select * from notification.dbo.databaseFileSizeLog (nolock)
GO
