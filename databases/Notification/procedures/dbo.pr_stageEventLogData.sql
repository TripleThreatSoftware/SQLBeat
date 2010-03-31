USE [Notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_stageEventLogData]    Script Date: 03/31/2010 10:39:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[pr_stageEventLogData] (@cLogType varchar(100), @cCategory varchar(200), @cComputerName varchar(200), @cMessage varchar(8000), @cSourceName varchar(200), @cTimeWritten varchar(200), @cType varchar(200), @cAUser varchar(200))
as
begin
	declare @nLength int
	set @nLength = len(@cLogType + @cCategory + @cComputerName + @cMessage + @cSourceName + @cTimeWritten + @cType + @cAUser)
	if @nLength > 8000
		set @cMessage = left(@cMessage, len(@cMessage) - (@nLength - 8000 + 2))

	insert into eventlog_stage (LogType,Category,ComputerName,Message,SourceName,TimeWritten,Type,AUser) values (@cLogType, @cCategory, @cComputerName, @cMessage, @cSourceName, @cTimeWritten, @cType, @cAUser)

end
