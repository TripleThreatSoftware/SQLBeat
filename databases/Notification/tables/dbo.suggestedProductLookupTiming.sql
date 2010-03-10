CREATE TABLE [dbo].[suggestedProductLookupTiming](
	[lookupGUID] [varchar](100) NULL,
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[timingMessage] [varchar](8000) NULL
) ON [PRIMARY]
GO
set identity_insert suggestedProductLookupTiming on
insert into suggestedProductLookupTiming (lookupGUID, ukey, ymd, timingMessage)
select lookupGUID, ukey, ymd, timingMessage from AppDb.dbo.suggestedProductLookupTiming
set identity_insert suggestedProductLookupTiming off
GO
use AppDb
GO
sp_rename 'suggestedProductLookupTiming', 'old_suggestedProductLookupTiming'
GO
ALTER TABLE [dbo].[suggestedProductLookupTiming] ADD  DEFAULT (getdate()) FOR [ymd]
GO
dbcc checkident(suggestedProductLookupTiming, reseed)
dbcc checkident(suggestedProductLookups, reseed)
GO
