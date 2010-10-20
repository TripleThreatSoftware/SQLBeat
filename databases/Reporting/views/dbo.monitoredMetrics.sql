SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[monitoredMetrics]    Script Date: 10/20/2010 11:53:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[monitoredMetrics]
as
select * from web03.sqlbeat.dbo.monitoredMetrics
GO
