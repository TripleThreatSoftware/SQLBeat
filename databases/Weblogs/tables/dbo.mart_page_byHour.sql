--select MIN(ymd), MAX(ymd) from mart_page_byday (nolock)
--select MIN(ymd), MAX(ymd) from mart_page_byhour (nolock)

drop table mart_page_byhour_archive
go
select *
	into mart_page_byhour_archive
	from mart_page_byhour (nolock)
	where ymd < '2011-12-13'
go

sp_rename 'mart_page_byhour', 'mart_page_byhour_old'
go

CREATE TABLE [dbo].[mart_page_byHour](
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ukey_site] [int] NULL,
	[ukey_uriStem] [int] NULL,
	[requestStatus] [int] NULL,
	[ymd] [datetime] NULL,
	[hour] [int] NULL,
	[numRequests] [int] NULL,
	[numRequests_human] [int] NULL,
	[uniques] [int] NULL,
	[uniques_human] [int] NULL,
	[pageLoadTime] [int] NULL,
	[pagePostTime] [int] NULL,
	[getTime] [int] NULL,
	[postTime] [int] NULL
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[mart_page_byHour] ADD  DEFAULT ((0)) FOR [pageLoadTime]
GO

set identity_insert mart_page_byhour on
insert into mart_page_byhour (ukey, ukey_site, ukey_uriStem, requestStatus, ymd, hour, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime)
select ukey, ukey_site, ukey_uriStem, requestStatus, ymd, hour, numRequests, numRequests_human, uniques, uniques_human, pageLoadTime, pagePostTime, getTime, postTime
	from mart_page_byhour_old (nolock)
	where ymd >= '2011-12-13'

set identity_insert mart_page_byhour off
