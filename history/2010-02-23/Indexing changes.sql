create index ix_schoolFTEData_fiscalYear_schoolID_systemID_total on schoolFTEData (fiscal_year, school_id, system_id, total) with fillfactor = 80
go
create index ix_schoolFTEData_fiscalYear_fiscalCount_schoolID_systemID_total on schoolFTEData (fiscal_year, fiscal_count, school_id, system_id, total) with fillfactor = 80
go
create index ix_schoolFTEData_fiscalYear_fiscalCount_schoolID_systemID_gr08 on schoolFTEData (fiscal_year, fiscal_count, school_id, system_id, gr08) with fillfactor = 80
go
create index ix_dwResponseSet_wizardID_multivalue_responseSetID on dwResponseSet (wizardID, multiValue, responseSetID) with fillfactor = 80
go
create index ix_organization_organizationCode_organizationID on organization (organizationCode, organizationID) with fillfactor = 80
go
create index ix_dwSection_sectionID_pageID on dwSection (sectionID, pageID) with fillfactor = 80
go
create index ix_dwSection_pageID_sectionID on dwSection (pageID, sectionID) with fillfactor = 80
go
create index ix_dwResponse_primaryQuestionID_questionID_responseSetID_responseInt on dwResponse (primaryQuestionID, questionID, responseSetID, responseInt) with fillfactor = 80
go
--create index ix_dwQuestion_questionID_questionIDentifier_questionText on dwQuestion (questionID, questionIdentifier) include (questionText) with fillfactor = 80
go
create index ix_dwQuestion_questionID_questionText on dwQuestion (questionID) include (questionText) with fillfactor = 80
go
create index ix_dwQuestion_questionID_questionIDentifier on dwQuestion (questionID, questionIdentifier) with fillfactor = 80
go

CREATE INDEX [ix_dwResponse_questionID_responseSetID_primaryQuestionID_choiceID_repeatNum_responseInt] ON [dbo].[DWResponse]
(
	[QuestionID] ASC,
	[ResponseSetID] ASC,
	[PrimaryQuestionID] ASC,
	[ChoiceID] ASC,
	[RepeatNum] ASC,
	responseInt
)WITH fillfactor = 80
go
create index ix_dwPage_wizardID_pageName_pageID on dwPage (wizardID, pageName, pageID) with fillfactor = 80
go
create index ix_dwPage_pageName_wizardID_pageID on dwPage (pageName, wizardID, pageID) with fillfactor = 80
go
create index ix_dwQuestion_sectionID_questionFormatID_questionID on dwQuestion (sectionID, questionFormatID, questionID) with fillfactor = 80
go
create index ix_dwQuestionFormat_questionFormatID on dwQuestionFormat (questionFormatID) with fillfactor = 80
go

create index ix_soPermission_defID_groupID_objectID_accessID on soPermission (defID, groupID, objectID, accessID) with fillfactor = 80
go
create index ix_soPermission_groupID_defID_objectID_accessID on soPermission (groupID, defID, objectID, accessID) with fillfactor = 80
go
create index ix_customGroups_customGroupID_organizationTypeID_personID_organizationRoleID_itApplicationRoleID on customGroups (customGroupID,organizationTypeID,personID,organizationRoleID,itApplicationRoleID) with fillfactor = 80
go

create index ix_soPermissionDef_ID_accessID on soPermissionDef (ID, accessID) with fillfactor = 80
go
create index ix_soPermissionDef_accessID_ID on soPermissionDef (accessID, ID) with fillfactor = 80
go
create index ix_soPermission_baseTypeID_groupID_defID_objectID_AccessID on soPermission (baseTypeID,groupID,defID,objectID,AccessID) with fillfactor = 80
go
create index ix_favorites_favoriteType_isActive_isPublic_folderID_startDate_endDate_favoriteID on favorites (favoriteType,isActive,isPublic,folderID,startDate,endDate,favoriteID) include (FavoriteValue, FavoriteName, FavoriteLink, FavoriteDesc, createdBy, createdDate, updatedBy, updatedDate) with fillfactor = 80
go
create index ix_provisionRequest_provisionRequestID_itApplicationRoleID on ProvisionRequest_ITApplicationRole (provisionRequestID, itApplicationRoleID) with fillfactor = 80
go
create index ix_provisionRequestOrganizationRole_provisionRequestID_organizationID on ProvisionRequest_OrganizationRole (provisionRequestID, organizationID) with fillfactor = 80
go
create index ix_provisionRequestOrganizationRole_organizationID_provisionRequestID on ProvisionRequest_OrganizationRole (organizationID, provisionRequestID) with fillfactor = 80
go

use schoolNutrition
go
create index ix_snRevenue_submitType_isActive_financialInformationID_revenueLookupID_revenueAmount on snRevenue (submitType, isActive, financialInformationID,revenueLookupID,revenueAmount) with fillfactor = 80
go
create index ix_snRevenueAdjustments_isActive_financialInformationID_revenueLookupID_amount on SNRevenueAdjustments (isActive,financialInformationID,revenueLookupID,amount) with fillfactor = 80
go
create index ix_snFinancialInformation_claimMonth_isActive_schoolInformationID_financialInformationID on snFinancialInformation (claimMonth,isActive,schoolInformationID,financialInformationID) with fillfactor = 80
go
create index ix_snSchoolInformation_fiscalYear_isActive_schoolInformationID_systemID on SNSchoolInformation (fiscalYear,isActive,schoolInformationID,systemID) with fillfactor = 80
go
