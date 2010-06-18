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
GO
