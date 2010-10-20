declare @cLicenseKey varchar(8000)
declare @nNumDays int
declare @nNumInstances int

set @nNumDays = 365*10
set @nNumInstances = 5

set @cLicenseKey =
	-- YYYY
	char(65 + convert(int, substring(convert(varchar(4), datePart(year, getDate())), 1, 1))) +
	char(65 + convert(int, substring(convert(varchar(4), datePart(year, getDate())), 2, 1))) +
	char(65 + convert(int, substring(convert(varchar(4), datePart(year, getDate())), 3, 1))) +
	char(65 + convert(int, substring(convert(varchar(4), datePart(year, getDate())), 4, 1))) +
	-- MM
	char(65 + convert(int, substring(right('00' + convert(varchar(2), datePart(month, getDate())), 2), 1, 1))) +
	char(65 + convert(int, substring(right('00' + convert(varchar(2), datePart(month, getDate())), 2), 2, 1))) +
	-- DD
	char(65 + convert(int, substring(right('00' + convert(varchar(2), datePart(day, getDate())), 2), 1, 1))) +
	char(65 + convert(int, substring(right('00' + convert(varchar(2), datePart(day, getDate())), 2), 2, 1))) +
	-- NNNN (license days)
	char(65 + convert(int, substring(right('0000' + convert(varchar(4), @nNumDays), 4), 1, 1))) +
	char(65 + convert(int, substring(right('0000' + convert(varchar(4), @nNumDays), 4), 2, 1))) +
	char(65 + convert(int, substring(right('0000' + convert(varchar(4), @nNumDays), 4), 3, 1))) +
	char(65 + convert(int, substring(right('0000' + convert(varchar(4), @nNumDays), 4), 4, 1))) +
	-- NNNN (license instances)
	char(65 + convert(int, substring(right('0000' + convert(varchar(4), @nNumInstances), 4), 1, 1))) +
	char(65 + convert(int, substring(right('0000' + convert(varchar(4), @nNumInstances), 4), 2, 1))) +
	char(65 + convert(int, substring(right('0000' + convert(varchar(4), @nNumInstances), 4), 3, 1))) +
	char(65 + convert(int, substring(right('0000' + convert(varchar(4), @nNumInstances), 4), 4, 1)))

select @cLicenseKey

-- add a 30 day license key for 1000 instances
insert into licenseKeys (keyString) values (@cLicenseKey)
