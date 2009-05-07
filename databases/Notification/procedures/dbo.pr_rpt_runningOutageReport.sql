/****** Object:  StoredProcedure [dbo].[pr_rpt_runningOutageReport]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pr_rpt_runningOutageReport]
as
begin
	declare @cThisSubject varchar(500)
	declare @cThisMessage varchar(8000)
	declare @nNumServersDown int

	set @cThisMessage = char(13) +
		left('ServerName' + space(20), 20) + ' ' +
		left('Last Available' + space(19), 19) + char(13) +
		replicate('=', 20) + ' ' +
		replicate('=', 19) + char(13)

	select @cThisMessage = @cThisMessage +
		left(isnull(a.serverName, 'N/A') + space(20), 20) + ' ' +
		isnull(convert(varchar(19), b.ymd, 120), 'N/A') + char(13)

		from dm_servers a (nolock)
		left outer join (
			select serverName, max(ymd) as ymd
				from pingLog (nolock)
				where isServerPingable = 1
				group by serverName
			) b on a.serverName = b.serverName
		where isEnabled = 1
			and isServerPingable = 0
			and pingCheck = 1
		order by a.serverName

	set @nNumServersDown = @@rowcount

	if @nNumServersDown > 0
	begin
		set @cThisSubject = 'SQLBeat : ' + convert(varchar(20), @nNumServersDown) + ' Servers down at ' + left(right(convert(varchar(20), getDate(), 120), 8), 5)

		print @cThisSubject
		print @cThisMessage

		exec pr_sendMessage '', 'DBA', @cThisSubject, @cThisMessage
	end
end
GO
