SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[v_getDate]    Script Date: 05/07/2009 10:30:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_getDate]
as
	select getDate() as ymd
GO
