IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pr_rpt_blockedQueries]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- exec pr_rpt_blockedQueries ''doe-monitor-sql'', ''2008-01-04 08:00:00.000'', ''2008-01-04 10:20:00.000''
-- exec pr_rpt_blockedQueries ''sqlcluster01'', ''2008-01-01'', ''2008-01-04''
-- select * from tmp_messageLog order by ymd desc
CREATE procedure [pr_rpt_blockedQueries] (@cServerName varchar(100), @dStartDate dateTime, @dEndDate dateTime)
as
begin

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -12, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	if dateDiff(hour, @dStartDate, @dEndDate) > 12
		set @dStartDate = dateAdd(hour, -12, @dEndDate)

--	insert into tmp_messageLog (messageText) values (''blocked queries called'' + isnull(@cServerName, '''') + ''||'' + convert(varchar(20), @dStartDate, 120) + ''||'' + convert(varchar(20), @dEndDate, 120))

	select ymd,
		spid,
		bufferContents,
		dbo.fn_returnTrimmedBuffer(bufferContents) as shortBuffer,
		lastBatchTime,
		hostName,
		programName,
		dbName,
		locks
		from processLog (nolock)
		where serverName = @cServerName
			and ymd >= @dStartDate
			and ymd <= @dEndDate
			and isBlocked = 1
		order by spid, hostName, programName, dbName, dbo.fn_returnTrimmedBuffer(bufferContents), lastBatchTime, ymd

end
'
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
