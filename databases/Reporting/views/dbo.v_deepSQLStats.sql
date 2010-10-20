/****** Object:  View [dbo].[v_deepSQLStats]    Script Date: 10/20/2010 11:53:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_deepSQLStats] as select * from notification.dbo.deepSQLStats (nolock)
GO
