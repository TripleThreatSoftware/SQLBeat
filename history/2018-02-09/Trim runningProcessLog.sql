---- select top 100 * from runningProcessLog
--delete from runningProcessLog with (tablock) where ymd < '2014-01-01'
--go
--delete from runningProcessLog with (tablock) where ymd < '2015-01-01'
--go
--delete from runningProcessLog with (tablock) where ymd < '2016-01-01'
--go
--delete from runningProcessLog with (tablock) where ymd < '2017-01-01'
--go
--delete from runningProcessLog with (tablock) where ymd < dateADd(month, -3, getDate())

select identity(int) as [ukey]
      ,[ukey_server]
      ,[ymd]
      ,[instance]
      ,[processName]
      ,[threadCount]
      ,[percentProcessorTime]
      ,[pageFileBytes]
      ,[poolNonpagedBytes]
      ,[poolPagedBytes]
      ,[privateBytes]
      ,[virtualBytes]
      ,[ioWriteBytesPerSecond]
      ,[ioReadBytesPerSecond]
	  into runningProcessLog_new
	  from runningProcessLog (nolock)
	  where  ymd >= dateADd(month, -3, getDate())
go

exec sp_rename 'runningProcessLog', 'runningProcessLog_old'
go


exec sp_rename 'runningProcessLog_new', 'runningProcessLog'
go

USE [Configuration]
GO

/****** Object:  Index [ix_runningProcessLog_ukey]    Script Date: 2/9/2018 11:51:18 AM ******/
CREATE CLUSTERED INDEX [ix_runningProcessLog_ukey] ON [dbo].[runningProcessLog]
(
	[ukey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
GO
USE [Configuration]
GO

/****** Object:  Index [ix_runningProcessLog_server_ymd_ukey]    Script Date: 2/9/2018 11:51:24 AM ******/
CREATE NONCLUSTERED INDEX [ix_runningProcessLog_server_ymd_ukey] ON [dbo].[runningProcessLog]
(
	[ukey_server] ASC,
	[ymd] ASC)

	include ([ukey])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70) ON [PRIMARY]
GO

drop table runningProcessLog_old
go
