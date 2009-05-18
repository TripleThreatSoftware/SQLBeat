/****** Object:  StoredProcedure [dbo].[pr_rpt_unauthorizedProductionAccess]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE         procedure [dbo].[pr_rpt_unauthorizedProductionAccess]
as
begin
	declare @bTesting bit
	declare @cThisSubject varchar(1000)
	declare @cThisMessage varchar(8000)
	declare @nThisUkey int

	set nocount on
	set ansi_warnings off

	set @bTesting = 0
	set @cThisMessage = ''
	set @cThisSubject = ''

	select
		@cThisMessage = @cThisMessage +
			left(isnull(serverName, '') + replicate(' ', 20), 20) +
			left(isnull(hostname, '') + replicate(' ', 15), 15) +
			left(isnull(login, '') + replicate(' ', 10), 10) +
			left(isnull(dbname, '') + replicate(' ', 15), 15) +
			left(isnull(command, '') + replicate(' ', 20), 20) +
			left(isnull(convert(varchar(20), lastDate, 120), '') + replicate(' ', 20), 20) +
			left(isnull(programName, '') + replicate(' ', 15), 15) +
			char(13)
		from (
			select serverName, hostName, login, dbname,
				case when isBlocker = 1 then 'BLOCKING' else command end as command,
				programName,
				max(ymd) as lastDate
				from processLog
				where (serverName like 'sqlserver\%' or serverName = 'chronicle1' or serverName = 'rt-pricebook1')
					and spid > 50
--					and login not like 'CORP\%'
					and ymd >= dateAdd(week, -1, getDate())
--					and hostname not in ('admin', 'smontgomery', 'fcallaway', 'tmgllc',
--						'intra1', 'intra2', 'LAWSONSTUDIO', 'TASKMSTR2')
--					and login <> 'remoteAdmin'
--					and not (hostname = 'sqlserver' and login = 'sa')
					and (
						(
							programName like '%query analyzer%'
							or programName like '%ms sqlem%'
							or programName like '%sqlclient data provider%'
							or programName like '%visual basic%'
							)
--						or (hostname like '%test%' and hostname <> 'store_test')
						)
				group by serverName, hostname, login, case when isBlocker = 1 then 'BLOCKING' else command end, dbname, programName
			) a
		order by hostname, login, dbname, command

	set @cThisSubject = 'SQLBeat : Weekly Production Access Report (' + convert(varchar(20), @@ROWCOUNT) + ' tattles)'

	set @cThisMessage = 'These accesses happened within the last week.

SERVER              HOST           LOGIN     DATABASE       COMMAND             LAST SEEN           PROGRAM
=================== ============== ========= ============== =================== =================== ==============
' + @cThisMessage

-- 	print @cThisSubject
-- 	print @cThisMessage

	if @bTesting = 1
	begin
		set @cThisSubject = '(TEST) ' + @cThisSubject
		exec pr_sendMessage '', 'DBA', @cThisSubject, @cThisMessage
	end
	else
	begin
		exec pr_sendMessage '', 'DBA', @cThisSubject, @cThisMessage
	end
end
GO
