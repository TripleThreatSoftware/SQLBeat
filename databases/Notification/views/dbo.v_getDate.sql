SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[v_getDate]    Script Date: 05/19/2009 13:59:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_getDate]
as
	select getDate() as ymd
GO
