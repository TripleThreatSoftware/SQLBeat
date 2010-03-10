CREATE TABLE [dbo].[suggestedProductLookups](
	[lookupGUID] [varchar](100) NULL,
	[ukey] [int] IDENTITY(1,1) NOT NULL,
	[ymd] [datetime] NULL,
	[sessionID] [varchar](100) NULL,
	[machineID] [varchar](100) NULL,
	[ukey_product] [int] NULL,
	[ukey_application] [int] NULL,
	[ukey_website] [int] NULL,
	[isRelated] [bit] NULL,
	[isCart] [bit] NULL,
	[isPerformance] [bit] NULL,
	[isAccessory] [bit] NULL,
	[numResults] [int] NULL
) ON [PRIMARY]
GO
set identity_insert suggestedProductLookups on
insert into suggestedProductLookups (lookupGUID, ukey, ymd, sessionID, machineID, ukey_product, ukey_application, ukey_website, isRelated, isCart, isPerformance, isAccessory, numResults)
select lookupGUID, ukey, ymd, sessionID, machineID, ukey_product, ukey_application, ukey_website, isRelated, isCart, isPerformance, isAccessory, numResults from AppDb.dbo.suggestedProductLookups
set identity_insert suggestedProductLookups off
GO
use AppDb
GO
sp_rename 'suggestedProductLookups', 'old_suggestedProductLookups'
GO
ALTER TABLE [dbo].[suggestedProductLookups] ADD  DEFAULT (getdate()) FOR [ymd]
GO
