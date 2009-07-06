CREATE procedure [dbo].[Switch.Transactions.DCCRanges.ExportBinary] (@cSource varchar(1), @cCurrencies varchar(500), @dActionDate dateTime, @cOutputFile varchar(500))
as
begin

--	declare @cCurrencies varchar(8000)
--	declare @dActionDate dateTime
--	declare @cSource varchar(1)
--	declare @cOutputFile varchar(1000)
--
--	set @cSource = 'F'
--	set @cCurrencies = '036,124,392,484,826,978'
--
--	--set @cSource = 'D'
--	--set @cCurrencies = '840'
--
--	set @dActionDate = '2008-04-03'
--	set @cOutputFile = 'c:\temp\sample_f_036124392484826978.bin'

	declare @cErrorStep varchar(500)
	declare @nErrorCode int
	declare @oFileSystem int
	declare @oTextStream int
	declare @oErrorObject int

	declare @bOutput varbinary(max)
	declare @bOutput2 varbinary(max)
	declare @cOutput varchar(max)
	declare @cOutput2 varchar(max)

	declare @cCurrencyList varchar(8000)
	declare @currencies table (currency varchar(20))

	set @dActionDate = convert(varchar(10), isnull(@dActionDate, getDate()), 120)
	set @cOutput2 = ''

	-- Set source to (F)oreign or (D)omestic. Default is D
	set @cOutput = '0x' + (select dbo.fn_stringToHexString(isnull(@cSource, 'D')))

	-- Add date
	set @cOutput = @cOutput +
		(
			select dbo.fn_stringToHexString(
				right('00' + convert(varchar(2), datePart(month, @dActionDate)), 2) +
				right('00' + convert(varchar(2), datePart(day, @dActionDate)), 2) +
				convert(varchar(4), datePart(year, @dActionDate))
				)
			)

	insert into @currencies (currency)
	select listItem
		from dbo.fn_makeTableFromList(@cCurrencies, ',')

	if isnull(@cSource, 'D') = 'D' and (select count(*) from @currencies) > 1
	begin
		select 'Only one currency may be specified for a Domestic file'
		return
	end

	-- Add number of currencies supported
--	if isnull(@cSource, 'D') = 'D'
--		set @cOutput = @cOutput + (select dbo.fn_stringToHexString('1'))
--	else
		set @cOutput = @cOutput + right('00' + (select convert(varchar(2), count(*)) from @currencies), 2)

	-- Add currencies list
	select @cOutput = @cOutput + (select dbo.fn_stringToHexString(currency))
		from @currencies

	select
		@cOutput2 = case when len(@cOutput + convert(varchar(9), low) + convert(varchar(9), high) + '41') > 43650
			then @cOutput2 + convert(varchar(9), low) + convert(varchar(9), high) + '41'
			else '' end,
		@cOutput = left(@cOutput + convert(varchar(9), low) + convert(varchar(9), high) + '41', 43650)
		from dccRanges_compressed a
		join @currencies b on a.currency = b.currency
		where a.actionDate >= @dActionDate
		order by low, high

	--select @cOutput, @cOutput2, len(@cOutput), len(@cOutput2)

	set @bOutput = (select dbo.fn_stringToVarBinary(@cOutput))
	set @bOutput2 = (select dbo.fn_stringToVarBinary(@cOutput2))

	set @cErrorStep = 'Opening ADODB.Stream'
	exec @nErrorCode = sp_OACreate 'ADODB.Stream' , @oFileSystem OUT

	if @nErrorCode = 0
	begin
		set @cErrorStep = 'Type'
		exec @nErrorCode = sp_OASetProperty @oFileSystem, 'Type', 2
	end
	else
		set @oErrorObject = @oFileSystem

	if @nErrorCode = 0
	begin
		set @cErrorStep = 'CharSet'
		exec @nErrorCode = sp_OASetProperty @oFileSystem, 'CharSet', 'Unicode'
	end
	else
		set @oErrorObject = @oFileSystem

	if @nErrorCode = 0
	begin
		set @cErrorStep = 'Open'
		exec @nErrorCode = sp_OAMethod @oFileSystem, 'Open'
	end
	else
		set @oErrorObject = @oFileSystem

	if @nErrorCode = 0
	begin
		set @cErrorStep = 'WriteText'

		exec @nErrorCode = sp_OAMethod @oFileSystem, 'WriteText', null, @bOutput
		exec @nErrorCode = sp_OAMethod @oFileSystem, 'WriteText', null, @bOutput2
	end
	else
		set @oErrorObject = @oTextStream

	if @nErrorCode = 0
	begin
		set @cErrorStep = 'SaveToFile'
		exec @nErrorCode = sp_OAMethod @oFileSystem, 'SaveToFile', null, @cOutputFile, 2
	end
	else
		set @oErrorObject = @oFileSystem

	if @nErrorCode <> 0
	begin
		declare @cErrorSource varchar(255)
		declare @cErrorDescription Varchar(255)
		declare @cHelpfile Varchar(255)
		declare @nHelpID int

		EXECUTE sp_OAGetErrorInfo @oErrorObject, @cErrorSource output, @cErrorDescription output, @cHelpfile output, @nHelpID output

		select @nErrorCode, @cErrorStep, @cErrorDescription
	end

	exec sp_OADestroy @oTextStream
	exec sp_OADestroy @oFileSystem
end
