/****** Object:  StoredProcedure [dbo].[pr_rpt_driveSpaceOverTime]    Script Date: 05/19/2009 13:59:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_rpt_driveSpaceOverTime] (@cServerName varchar(100))
as
begin

	create table #dataValues (setName varchar(200), seriesName varchar(100), axis_x varchar(100), axis_y decimal(20,4), sortOrder int identity)

	insert into #dataValues (setName, seriesName, axis_x, axis_y)
	select
		driveLetter,
		'drive space by hour',
		right(convert(varchar(10), min(ymd), 120), 2) + ' ' +
			case when datePart(hour, min(ymd)) <= 12 then convert(varchar(20), datePart(hour, min(ymd))) else convert(varchar(20), datePart(hour, min(ymd))-12) end +
			case when datePart(hour, min(ymd)) <= 12 then 'a' else 'p' end ,
		convert(decimal(10,2), convert(decimal(20,4), min(drivespace))/convert(decimal(20,4), 1000))
		from drivespacelog (nolock)
		where servername = @cServerName
			and ymd >= dateAdd(week, -1, getDate())
		group by driveLetter, convert(varchar(10), ymd, 120), datePart(hour, ymd) / 6
		order by driveLetter, convert(varchar(10), ymd, 120), datePart(hour, ymd) / 6

	exec pr_generateGoogleChartsRequest @nWidth=700, @nHeight=400, @bAbsoluteYAxis = 1

	drop table #dataValues

end
GO
