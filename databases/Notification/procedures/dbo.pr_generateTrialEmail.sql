--create table trialRequests (ukey int identity, ymd dateTime default getDate(),
--	firstName varchar(200), lastName varchar(200), companyName varchar(500), emailAddress varchar(200),
--	streetAddress varchar(2000), city varchar(500), state varchar(500), postalCode varchar(500),
--	phoneNumber varchar(200))
--go

-- select top 10 * from AppDb..messagesSent order by ymd desc
-- select * from trialRequests

-- exec pr_generateTrialEmail 'Cole', 'Getzler', 'TTS', 'cole@sqlbeat.com', 'street', 'city', 'state', 'postalcode', 'phone number'
-- exec pr_generateTrialEmail 'Kevin', 'Novak', 'TTS', 'knovak@sqlbeat.com', 'street', 'city', 'state', 'postalcode', 'phone number'
-- exec pr_generateTrialEmail 'Rusty', 'Johnson', 'TTS', 'rjohnson@sqlbeat.com', 'street', 'city', 'state', 'postalcode', 'phone number'
alter procedure [dbo].[pr_generateTrialEmail] (
	@cFirstName varchar(200), @cLastName varchar(200), @cCompanyName varchar(500), @cEmailAddress varchar(200),
	@cStreetAddress varchar(2000), @cCity varchar(500), @cState varchar(500), @cCountry varchar(200), @cPostalCode varchar(500),
	@cPhoneNumber varchar(200)
)
as
begin
	insert into trialRequests (firstName, lastName, companyName, emailAddress, streetAddress, city, state, postalCode, phoneNumber, country) values (
		@cFirstName, @cLastName, @cCompanyName, @cEmailAddress, @cStreetAddress, @cCity, @cState, @cPostalCode, @cPhoneNumber, @cCountry)

	declare @cSubject varchar(2000)
	declare @cBody varchar(8000)
	declare @cTo varchar(200)
	declare @cFrom varchar(200)

	set @cTo = @cEmailAddress
	set @cFrom = 'sales@sqlbeat.com'

	set @cSubject = 'SQLBeat free 30 day trial'

	set @cBody = 'Thank you for your interest in SQLBeat.<br><br>' +
		'You can begin your free 30 day trial by downloading and running the following: <br><a href="http://www.sqlbeat.com/sqlbeat_install.exe">www.sqlbeat.com/sqlbeat_install.exe</a><br><br>' +
		'We will be in touch with you over the next 48 hours to help answer any questions you may have about SQLBeat, and to offer assistance getting monitoring configured. If you have any questions, please email us at <a href="mailto:support@sqlbeat.com">support@sqlbeat.com</a> or call us directly at (404) 423-8040.<br><br>' +
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
		'First Name     : ' + isnull(@cFirstName, '') + '<br>' +
		'Last Name      : ' + isnull(@cLastName, '') + '<br>' +
		'Company Name   : ' + isnull(@cCompanyName, '') + '<br>' +
		'Email Address  : ' + isnull(@cEmailAddress, '') + '<br>' +
		'Street Address : ' + isnull(@cStreetAddress, '') + '<br>' +
		'City           : ' + isnull(@cCity, '') + '<br>' +
		'State          : ' + isnull(@cState, '') + '<br>' +
		'Country        : ' + isnull(@cCountry, '') + '<br>' +
		'Postal Code    : ' + isnull(@cPostalCode, '') + '<br>' +
		'Phone          : ' + isnull(@cPhoneNumber, '')

	exec AppDb.dbo.pr_sendEmail @cFrom, 'sales@sqlbeat.com', @cSubject, @cBody
end

GO
