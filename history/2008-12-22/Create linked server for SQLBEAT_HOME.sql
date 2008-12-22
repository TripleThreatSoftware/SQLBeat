EXEC master.dbo.sp_addlinkedserver @server = N'SQLBEAT_HOME', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'SQLBEAT_HOME',@useself=N'False',@locallogin=NULL,@rmtuser=N'remote',@rmtpassword='REDACTED'

GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'rpc', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'rpc out', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'SQLBEAT_HOME', @optname=N'use remote collation', @optvalue=N'true'
