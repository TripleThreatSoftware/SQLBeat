USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_stageEventLogData_test]    Script Date: 03/31/2010 10:14:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_stageEventLogData_test] (@cLogType varchar(100), @cCategory varchar(200), @cComputerName varchar(200), @cMessage varchar(8000), @cSourceName varchar(200), @cTimeWritten varchar(200), @cType varchar(200), @cAUser varchar(200))
as
begin

	insert into eventlog_test (LogType,Category,ComputerName,Message,SourceName,TimeWritten,Type,AUser) values (@cLogType, @cCategory, @cComputerName, @cMessage, @cSourceName, @cTimeWritten, @cType, @cAUser)

end

truncate table eventlog_test
select * from eventlog_test
select * from eventlog_history where servername = 'Test' order by ymd desc
select * from eventlog_history order by ymd desc

select dbo.fn_returnUTCDate('2010-03-30')
