declare @cSQLString nvarchar(4000)

-- select * from dm_servers order by servername

set @cSQLString = 'c:\shared' + '\osql -Sweb04 -USQLProcess -P"REDACTED" -n -h-1 -w300 -dmaster -i"c:\shared\runningServices.SQL"'
exec master..xp_cmdshell @cSQLString

-- exec master..xp_cmdshell 'type c:\shared\runningServices.SQL'

update dm_servers set serviceCheck = 1 where servername in ('web04', 'web06', 'sqldb26','sqldb27','sqldm01.PRO','web01','web02','Web09','web15','web16-remote','web17','web18','web19','web20','web21','web22','web25')
