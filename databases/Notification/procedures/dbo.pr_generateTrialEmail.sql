SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--create table trialRequests (ukey int identity, ymd dateTime default getDate(),
--	firstName varchar(200), lastName varchar(200), companyName varchar(500), emailAddress varchar(200),
--	streetAddress varchar(2000), city varchar(500), state varchar(500), postalCode varchar(500),
--	phoneNumber varchar(200))
--go

-- select top 10 * from AppDb..messagesSent order by ymd desc
-- select * from trialRequests

-- exec pr_generateTrialEmail 'Cole', 'Getzler', 'TTS', 'cole@sqlbeat.com', 'street', 'city', 'state', 'country', 'postalcode', 'phone number'
-- exec pr_generateTrialEmail 'Kevin', 'Novak', 'TTS', 'knovak@sqlbeat.com', 'street', 'city', 'state', 'postalcode', 'phone number'
-- exec pr_generateTrialEmail 'Rusty', 'Johnson', 'TTS', 'rjohnson@sqlbeat.com', 'street', 'city', 'state', 'postalcode', 'phone number'
ALTER procedure [dbo].[pr_generateTrialEmail] (
	@cFirstName varchar(200) = '', @cLastName varchar(200) = '', @cCompanyName varchar(500) = '', @cEmailAddress varchar(200) = '',
	@cCity varchar(500) = '', @cState varchar(500) = '', @cCountry varchar(200) = '', @cPhoneNumber varchar(200) = '', @cCompanySize varchar(200) = '',
	@bEventLog bit = 0, @bInstalledSoftware bit = 0, @bWMIMonitoring bit = 0, @bIISMonitoring bit = 0, @bURLMonitoring bit = 0, @bRemoteMonitoring bit = 0
)
as
begin
	insert into trialRequests (firstName, lastName, companyName, emailAddress, city, state, phoneNumber, country, companySize, eventLog, installedSoftware, wmiMonitoring, iisMonitoring, urlMonitoring, remoteMonitoring) values (
		@cFirstName, @cLastName, @cCompanyName, @cEmailAddress, @cCity, @cState, @cPhoneNumber, @cCountry, @cCompanySize, @bEventLog, @bInstalledSoftware, @bWMIMonitoring, @bIISMonitoring, @bURLMonitoring, @bRemoteMonitoring)

	declare @cSubject varchar(2000)
	declare @cBody varchar(8000)
	declare @cTo varchar(200)
	declare @cFrom varchar(200)

	set @cTo = @cEmailAddress
	set @cFrom = 'sales@sqlbeat.com'

	set @cSubject = 'SQLBeat information request'

	set @cBody = 'Thank you for your interest in SQLBeat.<br><br>' +
		'We will be in touch with you in the next 24 hours to begin putting together customized SQLBeat pricing for your environment, and to schedule a time to work with you to establish your free 30 day trial of SQLBeat. As always, if you have any questions, please email us at <a href="mailto:sales@sqlbeat.com">sales@sqlbeat.com</a> or call us directly at (404) 423-8040.<br><br>' +
		'Thanks,<br>' +
		'The SQLBeat Team'

	-- now, roll in a leading style sheet declaration

	set @cBody = '<style> ' +
		'.emailBody {font-family: verdana; font-size: 9pt;} ' +
		'</style>' + '<div class="emailBody">' + @cBody + '</div>'

	exec AppDb.dbo.pr_sendEmail @cFrom, @cTo, @cSubject, @cBody

	--******************************************************************************

	set @cSubject = 'SQLBeat trial request: ' +
		case
			when isnull(@cCompanyName, '') <> '' then @cCompanyName
			when isnull(@cFirstName + ' ' + @cLastName, '') <> '' then @cFirstName + ' ' + @cLastName
			else 'N/A'
			end

	set @cBody =
		'First Name         : ' + isnull(@cFirstName, '') + '<br>' +
		'Last Name          : ' + isnull(@cLastName, '') + '<br>' +
		'Company Name       : ' + isnull(@cCompanyName, '') + '<br>' +
		'Company Size       : ' + isnull(@cCompanySize, '') + '<br>' +
		'Email Address      : ' + isnull(@cEmailAddress, '') + '<br>' +
		'City               : ' + isnull(@cCity, '') + '<br>' +
		'State              : ' + isnull(@cState, '') + '<br>' +
		'Country            : ' + isnull(@cCountry, '') + '<br>' +
		'Phone              : ' + isnull(@cPhoneNumber, '') + '<br>' +
		'EventLog           : ' + case when @bEventLog = 1 then 'Yes' else 'No' end + '<br>' +
		'Installed Software : ' + case when @bInstalledSoftware = 1 then 'Yes' else 'No' end + '<br>' +
		'WMI Monitoring     : ' + case when @bWMIMonitoring = 1 then 'Yes' else 'No' end + '<br>' +
		'IIS Monitoring     : ' + case when @bIISMonitoring = 1 then 'Yes' else 'No' end + '<br>' +
		'URL Monitoring     : ' + case when @bURLMonitoring = 1 then 'Yes' else 'No' end + '<br>' +
		'Remote Monitoring  : ' + case when @bRemoteMonitoring = 1 then 'Yes' else 'No' end

	exec AppDb.dbo.pr_sendEmail @cFrom, 'sales@sqlbeat.com', @cSubject, @cBody
end
