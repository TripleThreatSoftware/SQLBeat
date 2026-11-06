-- ================================================================================================
-- Audit.dbo.pr_monitorActiveServers
--
-- Runs pr_monitorFiles against C$\Windows\System32\drivers\etc on every server, so key Windows
-- configuration files are watched even before anyone configures them.
-- ================================================================================================
/****** Object:  StoredProcedure [dbo].[pr_monitorActiveServers]    Script Date: 11/6/2026 9:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[pr_monitorActiveServers]
AS
BEGIN

   DECLARE @cPath VARCHAR(500)
   DECLARE @cName VARCHAR(500)
   DECLARE @iRowCounter INT
   DECLARE @iNumRows INT

   CREATE TABLE #ActiveServers (rowID INT IDENTITY(1,1), serverName VARCHAR(500))

   --Get list of active servers to check
   INSERT INTO #ActiveServers
      SELECT [serverName]
	  FROM Notification.dbo.dm_servers
	  WHERE isEnabled = 1

   -- Get row count
   SET @iNumRows  = @@ROWCOUNT

   IF @iNumROws > 0
   BEGIN

      SET @iRowCounter = 1

      WHILE @iRowCounter < @iNumRows
      BEGIN

         --Get server name from list
         SELECT @cName = serverName
         FROM #ActiveServers
         WHERE rowID = @iRowCounter

         SET @cPath = '\\' + @cName + '\C$\Windows\System32\drivers\etc'

         EXEC pr_monitorFiles @cPath

	     SET @iRowCounter = @iRowCounter + 1
      END
   END
   ELSE
      PRINT 'NO ACTIVE SERVERS TO MONITOR'

   DROP TABLE #ActiveServers
END
GO
