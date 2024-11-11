/****** Object:  StoredProcedure [dbo].[pr_generateTrialEmail]    Script Date: 11/11/2024 8:55:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop table trialRequests


-- select top 10 * from AppDb..messagesSent order by ymd desc
-- select * from trialRequests

-- exec pr_generateTrialEmail 'Cole', 'Getzler', 'TTS', 'cole@triplethreatsoftware.com', 'street', 'city', 'state', 'country', 'postalcode', 'phone number'
-- exec pr_generateTrialEmail 'Kevin', 'Novak', 'TTS', 'knovak@sqlbeat.com', 'street', 'city', 'state', 'postalcode', 'phone number'
-- exec pr_generateTrialEmail 'Rusty', 'Johnson', 'TTS', 'rjohnson@sqlbeat.com', 'street', 'city', 'state', 'postalcode', 'phone number'
ALTER procedure [dbo].[pr_generateTrialEmail] (
	@cFirstName varchar(200) = '', @cLastName varchar(200) = '', @cCompanyName varchar(500) = '', @cEmailAddress varchar(200) = '', @cStreetAddress varchar(500) = '',
	@cCity varchar(500) = '', @cState varchar(500) = '', @cCountry varchar(200) = '', @cPostalCode varchar(100) = '', @cPhoneNumber varchar(200) = ''
)
as
begin
	if charindex('?', isnull(@cCompanyName, '')) > 0
		or charindex('http', isnull(@cCompanyName, '')) > 0
		return

	if not exists (select top 1 id from sysobjects where name = 'trialRequests')
		create table trialRequests (ukey int identity, ymd dateTime default getDate(),
			firstName varchar(200), lastName varchar(200), companyName varchar(500), emailAddress varchar(200),
			streetAddress varchar(2000), city varchar(500), state varchar(500), country varchar(500), postalCode varchar(500),
			phoneNumber varchar(200))

	insert into trialRequests (firstName, lastName, companyName, emailAddress, streetAddress, city, state, phoneNumber, country, postalCode) values (
		@cFirstName, @cLastName, @cCompanyName, @cEmailAddress, @cStreetAddress, @cCity, @cState, @cPhoneNumber, @cCountry, @cPostalCode)

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

	exec dbo.sp_send_cdosysmail @cFrom, @cTo, @cSubject, null, null, @cBody

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
		'Email Address      : ' + isnull(@cEmailAddress, '') + '<br>' +
		'Address            : ' + isnull(@cStreetAddress, '') + '<br>' +
		'City               : ' + isnull(@cCity, '') + '<br>' +
		'State              : ' + isnull(@cState, '') + '<br>' +
		'Country            : ' + isnull(@cCountry, '') + '<br>' +
		'Postal Code        : ' + isnull(@cPostalCode, '') + '<br>' +
		'Phone              : ' + isnull(@cPhoneNumber, '') + '<br>'

	exec dbo.sp_send_cdosysmail @cFrom, 'cole@sqlbeat.com', @cSubject, null, null, @cBody
end
GO
