create view v_eventLog as select * from notification.dbo.eventLog (nolock)
GO
