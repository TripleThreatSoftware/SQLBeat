-- select dbo.fn_isLicenseValid()
-- drop function fn_isLicenseValid
-- sp_helptext 'fn_isLicenseValid'
alter function fn_isLicenseValid ()
returns bit
with encryption
as
begin
	declare @bIsValid bit
	declare @nUkeyLicenseKey int
	declare @cYearPart varchar(4)
	declare @cMonthPart varchar(2)
	declare @cDayPart varchar(2)
	declare @nNumDays int
	declare @nNumInstances int
	declare @cKeyString varchar(8000)
	declare @dStartDate dateTime

	set @bIsValid = 0
	set @nUkeyLicenseKey = 0

	while exists (select top 1 ukey from licenseKeys where ukey > @nUkeyLicenseKey)
		and @bIsValid = 0
	begin
		select top 1
			@nUkeyLicenseKey = ukey,
			@cKeyString = keyString
			from licenseKeys (nolock)
			where ukey > @nUkeyLicenseKey
			order by ukey

		if len(@cKeyString) = 16
		begin
			set @cYearPart = substring(@cKeyString, 1, 4)
			set @cMonthPart = substring(@cKeyString, 5, 2)
			set @cDayPart = substring(@cKeyString, 7, 2)

			set @nNumDays = convert(int,
				convert(varchar(1), ascii(substring(@cKeyString, 9, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cKeyString, 10, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cKeyString, 11, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cKeyString, 12, 1)) - 65)
				)

			set @nNumInstances = convert(int,
				convert(varchar(1), ascii(substring(@cKeyString, 13, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cKeyString, 14, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cKeyString, 15, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cKeyString, 16, 1)) - 65)
				)

			set @dStartDate = convert(dateTime,
				-- YYYYMMDD
				convert(varchar(1), ascii(substring(@cYearPart, 1, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cYearPart, 2, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cYearPart, 3, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cYearPart, 4, 1)) - 65) +
				'-' +
				convert(varchar(1), ascii(substring(@cMonthPart, 1, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cMonthPart, 2, 1)) - 65) +
				'-' +
				convert(varchar(1), ascii(substring(@cDayPart, 1, 1)) - 65) +
				convert(varchar(1), ascii(substring(@cDayPart, 2, 1)) - 65)
				)

			if dateAdd(day, @nNumDays, @dStartDate) >= getDate()
			begin
				if @nNumInstances >= (select count(*) from notification.dbo.dm_servers (nolock) where isEnabled = 1)
				begin
					set @bIsValid = 1
				end
			end

			--print 'Instances: ' + convert(varchar(20), @nNumInstances)
			--print 'Days: ' + convert(varchar(20), @nNumDays)
			--print 'Starting: ' + convert(varchar(20), @dStartDate, 120)
			--if @bIsValid= 1
			--	print 'VALID'
			--else
			--	print 'INVALID'
			--print '----------------'

		end
	end

--select @bIsValid

	return @bIsValid
end
