create procedure [dbo].[pr_stageEventLogData] (@cLogType varchar(100), @cCategory varchar(200), @cComputerName varchar(200), @cMessage varchar(8000), @cSourceName varchar(200), @cTimeWritten varchar(200), @cType varchar(200), @cAUser varchar(200))
as
begin

	insert into eventlog_stage (LogType,Category,ComputerName,Message,SourceName,TimeWritten,Type,AUser) values (@cLogType, @cCategory, @cComputerName, @cMessage, @cSourceName, @cTimeWritten, @cType, @cAUser)

end
GO
