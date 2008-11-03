-- exec pr_rpt_enterprisePacketLoss null, null
create procedure pr_rpt_enterprisePacketLoss (@dStartDate dateTime, @dEndDate dateTime)
as
begin
	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -72, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	select
		top 500
		ymd, serverName,
		replace(replace(serverPingResults, char(13), '<br>'), '<br><br>', '<br>') as serverPingResults
		from pingLog (nolock)
		where serverPingResults not like '%received = 4%'
			and ymd >= @dStartDate
			and ymd <= @dEndDate
		order by ymd desc
end



GO
