-- sp_who2


USE [master]
GO
IF EXISTS (SELECT * FROM sys.databases WHERE NAME = 'Scheduler')
	DROP DATABASE Scheduler
GO
CREATE DATABASE Scheduler
GO
-- set the database to trustworthy and enable service broker in it
ALTER DATABASE Scheduler SET TRUSTWORTHY ON, ENABLE_BROKER
GO
USE Scheduler


---------------------------------------------------------------------------------------
-- FIRST CREATE dbo.F_ISO_WEEK_OF_YEAR (http://www.sqlteam.com/forums/topic.asp?TOPIC_ID=60510)
--	AND dbo.F_TABLE_DATE HERE (http://www.sqlteam.com/forums/topic.asp?TOPIC_ID=61519) >
---------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
---- CREATE SERVICE BROKER OBJECTS, STORED PROCEDURES AND USER DEFINED FUNCTIONS ----
-------------------------------------------------------------------------------------
GO
IF OBJECT_ID('pr_addJobSchedule') IS NOT NULL
	DROP PROC pr_addJobSchedule
GO
IF OBJECT_ID('pr_removeJobSchedule') IS NOT NULL
	DROP PROC pr_removeJobSchedule
GO
IF OBJECT_ID('pr_addScheduledJob') IS NOT NULL
	DROP PROC pr_addScheduledJob
GO
IF OBJECT_ID('pr_removeScheduledJob') IS NOT NULL
	DROP PROC pr_removeScheduledJob
GO
IF OBJECT_ID('pr_addScheduledJobStep') IS NOT NULL
	DROP PROC pr_addScheduledJobStep
GO
IF OBJECT_ID('pr_removeScheduledJobStep') IS NOT NULL
	DROP PROC pr_removeScheduledJobStep
GO
IF OBJECT_ID('pr_startScheduledJob') IS NOT NULL
	DROP PROC pr_startScheduledJob
GO
IF OBJECT_ID('pr_stopScheduledJob') IS NOT NULL
	DROP PROC pr_stopScheduledJob
GO
IF OBJECT_ID('pr_runScheduledJobSteps') IS NOT NULL
	DROP PROC pr_runScheduledJobSteps
GO
IF OBJECT_ID('pr_runScheduledJob') IS NOT NULL
	DROP PROC pr_runScheduledJob
GO
IF OBJECT_ID('dbo.fn_getNextRunTime') IS NOT NULL
	DROP FUNCTION dbo.fn_getNextRunTime
GO
