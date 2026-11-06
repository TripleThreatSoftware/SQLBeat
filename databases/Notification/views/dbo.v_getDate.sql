/****** Object:  View [dbo].[v_getDate]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_getDate]
as
	select getDate() as ymd
GO
