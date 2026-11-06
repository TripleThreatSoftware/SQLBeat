/****** Object:  UserDefinedFunction [dbo].[fn_returnTrimmedBuffer]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select dbo.fn_returnTrimmedBuffer(' ---- =========================================================================== ---- Author:<Author:   a contractor> ---- Create date: <Create Date: 03:17:2008> ---- Updated date : Siva: 07:16:2008 - Tested the Summer process ---- Description:<Description: Save Summer Claims and Financial Data > ---- ============================================================================ CREATE PROCEDURE [dbo].[usp_SNSummerProcess] @PFiscalYear int, @ClaimMonth int, @SystemId Varchar(3), @UserId varchar(128) as --declare @PFiscalYear int,@ClaimMonth i nt,@SystemId Varchar(3),@UserId varchar(128) ---- --select @PFiscalYear=0,@ClaimMonth=6,@SystemId="621",@UserId="user@example.org"  declare @FiscalYear int declare @FinCnt int declare @ClmCnt int declare @DE107Cnt int declare @SFACount int declare @SchoolId varchar(4) declare @SchoolName varchar(100) declare @ErrMsgFin Varchar(max) declare @ErrMsgClm Varchar(max) declare @PrevClaimMonth int declare @PrevFiscalYear int declare @NeedDE107 int declare @SchoolInformationId int declare @FinancialInformationID int declare @SystemReimbursementClaimID int decla re @MealCountId int Declare @KeyValue Int Declare @CalendarDate datetime  DECLARE @SSClosedSAPP table ( SchoolAppParticipationProgramDetailID int )   begin set @ErrMsgFin="" set @ErrMsgClm="" SET @FiscalYear=@PFiscalYear if @PFiscalYear=0 and @ClaimMonth=7 set @Fisca lYear=year(getdate())+1  if @PFiscalYear=0 and @ClaimMonth=6 set @FiscalYear=year(getdate())  --Select @FiscalYear=2009 --Remove After Testing  if @ClaimMonth=7 begin set @PrevFiscalYear=@FiscalYear-1 set @PrevClaimMonth=6 end if @ClaimMonth=6 begin set @PrevFisc alYear=@FiscalYear set @PrevClaimMonth=5 end  SELECT @CalendarDate=Convert(datetime,(Select Case when (@ClaimMonth > 6 and @ClaimMonth <=12) Then convert(varchar,@ClaimMonth) + "/" + "01" + "/" + convert(varchar,@FiscalYear-1) Else convert(varchar,@ClaimMonth) + "/" + "01" + "/" + convert(varchar,@FiscalYear) End)) --Print @CalendarDate   --Print @FiscalYear --Print @PrevFiscalYear --Print @PrevClaimMonth  -- Check Claims Allowed for this FiscalYear Select @KeyValue=ClaimsAllowed from dbo.SNFiscalYear where FiscalYear=@Fisca lYear IF(ISNull(@KeyValue,0)=0) Begin Select "All data entry forms have been disabled at this time. Please contact Claim Administrator." as ErrMsg return End  -- Check SAM Status Select @SFACount=Count(SystemCertificationID) From ( SELECT SystemCertificationID,SFA.Fi scalYear, SFA.SystemID, WS.WFObjectTypeID, WS.WFStatusID FROM  SNSystemCertification AS SFA INNER JOIN WFObjectStatus AS WS ON SFA.SystemCertificationID = WS.WFObjectID WHERESFA.FiscalYear=@FiscalYear and SFA.SystemID=@SystemId and WS.WFObjectTypeID = 3 and WS. WFStatusID = 5 ) as A  if @SFACount=0 begin select"<B>SAM has not been approved for ')

CREATE function [dbo].[fn_returnTrimmedBuffer] (@cBufferContents varchar(8000))
returns varchar(500)
as
begin
	declare @cReturnString varchar(500)
	declare @nTrimPosition int
	declare @cWorkingBuffer varchar(8000)
	declare @nCounter int

	if @cBufferContents like 'begin tran%'
		return 'AdHoc User Code'

	set @nCounter = 0

	-- trim comments
	while left(@cBufferContents, 2) = '--'
		and (
			charindex(char(13), @cBufferContents) > 0
			or charindex(space(2), substring(@cBufferContents, 3, 8000)) > 0
			or charindex('--', substring(@cBufferContents, 3, 8000)) > 0
			)
		and @nCounter < 500
	begin
		set @nTrimPosition = 9999
		if charindex(char(13), substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(char(13), substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(char(13), substring(@cBufferContents, 3, 8000))
		if charindex(space(2), substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex(space(2), substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex(space(2), substring(@cBufferContents, 3, 8000)) + 2
		if charindex('--', substring(@cBufferContents, 3, 8000)) < @nTrimPosition and charindex('--', substring(@cBufferContents, 3, 8000)) <> 0
			set @nTrimPosition = charindex('--', substring(@cBufferContents, 3, 8000)) + 2

		set @cBufferContents = ltrim(rtrim(substring(@cBufferContents, @nTrimPosition , 8000)))
--		set @nTrimCounter = @nTrimCounter + 1

		set @nCounter = @nCounter + 1
	end

	set @cBufferContents = rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(replace(@cBufferContents, char(9), ' '), char(13), ' '), char(10), ' '), ']', ''), '[', ''), 'dbo.', ''), '~', ''), 'CREATE PROC ', 'CREATE PROCEDURE '), 'exec ', '')))

	set @cBufferContents =
		replace(replace(
				@cBufferContents,
				' S' + space(1) + 'ET', ' SET'),
				' SE' + space(1) + 'T', ' SET')

	set @cBufferContents =
		replace(replace(replace(
				@cBufferContents,
				'W' + space(1) + 'ITH', 'WITH'),
				'WI' + space(1) + 'TH', 'WITH'),
				'WIT' + space(1) + 'H', 'WITH')

	set @cBufferContents =
		replace(replace(replace(replace(replace(
				@cBufferContents,
				'U' + space(1) + 'PDATE', 'UPDATE'),
				'UP' + space(1) + 'DATE', 'UPDATE'),
				'UPD' + space(1) + 'ATE', 'UPDATE'),
				'UPDA' + space(1) + 'TE', 'UPDATE'),
				'UPDAT' + space(1) + 'E', 'UPDATE')

	set @cBufferContents =
		replace(replace(replace(replace(replace(
				@cBufferContents,
				'S' + space(1) + 'ELECT', 'SELECT'),
				'SE' + space(1) + 'LECT', 'SELECT'),
				'SEL' + space(1) + 'ECT', 'SELECT'),
				'SELE' + space(1) + 'CT', 'SELECT'),
				'SELEC' + space(1) + 'T', 'SELECT')

	set @cBufferContents =
		replace(replace(replace(replace(replace(
				@cBufferContents,
				'C' + space(1) + 'REATE', 'CREATE'),
				'CR' + space(1) + 'EATE', 'CREATE'),
				'CRE' + space(1) + 'ATE', 'CREATE'),
				'CREA' + space(1) + 'TE', 'CREATE'),
				'CREAT' + space(1) + 'E', 'CREATE')

	set @cBufferContents =
		replace(replace(replace(replace(replace(
				@cBufferContents,
				'I' + space(1) + 'NSERT', 'INSERT'),
				'IN' + space(1) + 'SERT', 'INSERT'),
				'INS' + space(1) + 'ERT', 'INSERT'),
				'INSE' + space(1) + 'RT', 'INSERT'),
				'INSER' + space(1) + 'T', 'INSERT')

	set @cBufferContents =
		replace(replace(replace(replace(
				@cBufferContents,
				'W' + space(1) + 'HERE', 'WHERE'),
				'WH' + space(1) + 'ERE', 'WHERE'),
				'WHE' + space(1) + 'RE', 'WHERE'),
				'WHER' + space(1) + 'E', 'WHERE')

	set @cBufferContents =
		replace(replace(replace(replace(replace(replace(replace(replace(
				@cBufferContents,
				'P' + space(1) + 'ROCEDURE', 'PROCEDURE'),
				'PR' + space(1) + 'OCEDURE', 'PROCEDURE'),
				'PRO' + space(1) + 'CEDURE', 'PROCEDURE'),
				'PROC' + space(1) + 'EDURE', 'PROCEDURE'),
				'PROCE' + space(1) + 'DURE', 'PROCEDURE'),
				'PROCED' + space(1) + 'URE', 'PROCEDURE'),
				'PROCEDU' + space(1) + 'RE', 'PROCEDURE'),
				'PROCEDUR' + space(1) + 'E', 'PROCEDURE')

	set @cBufferContents =
		replace(replace(replace(replace(replace(replace(replace(
				@cBufferContents,
				'F' + space(1) + 'UNCTION', 'FUNCTION'),
				'FU' + space(1) + 'NCTION', 'FUNCTION'),
				'FUN' + space(1) + 'CTION', 'FUNCTION'),
				'FUNC' + space(1) + 'TION', 'FUNCTION'),
				'FUNCT' + space(1) + 'ION', 'FUNCTION'),
				'FUNCTI' + space(1) + 'ON', 'FUNCTION'),
				'FUNCTIO' + space(1) + 'N', 'FUNCTION')

	if left(@cBufferContents, 2) = '/*'
		set @cBufferContents = substring(@cBufferContents, charindex('*/', @cBufferContents) + 2, 8000)

	set @cWorkingBuffer = replace(@cBufferContents, space(1), space(0))

	if (
			(patindex('%createprocedure%', @cWorkingBuffer) < patindex('%insertinto%', @cWorkingBuffer) or patindex('%insertinto%', @cWorkingBuffer) = 0)
			and (patindex('%createprocedure%', @cWorkingBuffer) < patindex('%select%from%', @cWorkingBuffer) or patindex('%select%from%', @cWorkingBuffer) = 0)
			and (patindex('%createprocedure%', @cWorkingBuffer) < patindex('%update%set%', @cWorkingBuffer) or patindex('%update%set%', @cWorkingBuffer) = 0)
			and (patindex('%createprocedure%', @cWorkingBuffer) < charindex('@', @cWorkingBuffer) or charindex('@', @cWorkingBuffer) = 0)
			and patindex('%createprocedure%', @cWorkingBuffer) > 0
		)
		or (
			(patindex('%createfunction%', @cWorkingBuffer) < patindex('%insertinto%', @cWorkingBuffer) or patindex('%insertinto%', @cWorkingBuffer) = 0)
			and (patindex('%createfunction%', @cWorkingBuffer) < patindex('%select%from%', @cWorkingBuffer) or patindex('%select%from%', @cWorkingBuffer) = 0)
			and (patindex('%createfunction%', @cWorkingBuffer) < patindex('%update%set%', @cWorkingBuffer) or patindex('%update%set%', @cWorkingBuffer) = 0)
			and patindex('%createfunction%', @cWorkingBuffer) > 0
		)
	begin
		set @cBufferContents = replace(@cBufferContents, 'with ', '$$')

		if charindex(' as ', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex(' as ', @cBufferContents) - 1)

		set @cBufferContents = replace(replace(replace(replace(replace(@cBufferContents, space(1), space(0)), char(9), space(0)), char(13), space(0)), char(10), space(0)), ascii(32), '')
		set @cBufferContents = replace(replace(replace(replace(@cBufferContents, 'createprocedure', '~~'), 'createproc', '~~'), 'createfunction', '~~'), 'createfunc', '~~')

		if charindex('~~', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, charindex('~~', @cBufferContents) + 2, 8000)

		if charindex('$$', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, 1, charindex('$$', @cBufferContents) - 1)

		if charindex('(', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('(', @cBufferContents) - 1)
		if charindex('@', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('@', @cBufferContents) - 1)
		if charindex('asbegin', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('asbegin', @cBufferContents) - 1)
		if charindex('asdeclare', @cBufferContents) > 0
			set @cBufferContents = left(@cBufferContents, charindex('asdeclare', @cBufferContents) - 1)
		else
			if charindex('asselect', @cBufferContents) > 0
				set @cBufferContents = left(@cBufferContents, charindex('asselect', @cBufferContents) - 1)
				else
					if charindex('AS', @cBufferContents) > 0 and charindex('begin', @cBufferContents) > 0
						set @cBufferContents = left(@cBufferContents, charindex('AS', @cBufferContents) - 1)

		set @cReturnString = left(@cBufferContents, 500)
	end
	else
	begin
		if left(@cBufferContents, 1) = '(' and charindex('))', @cBufferContents) > 0
			set @cBufferContents = substring(@cBufferContents, charindex('))', @cBufferContents) + 2, 8000)

		if left(@cBufferContents, 100) like '%insert into%'
		begin
			set @cBufferContents = replace(replace(replace(@cBufferContents, 'SELECT', '~~'), 'EXEC', '~~'), 'VALUES', '~~')

			if charindex('~~', @cBufferContents) >= 1
				set @cReturnString = left(@cBufferContents, charindex('~~', @cBufferContents) - 1)

			if left(@cReturnString, 1) = '('
				set @cReturnString = substring(@cReturnString, charindex('insert into', @cReturnString), 500)
		end
		else
		begin
			declare @cWhereClause varchar(8000)
			set @cWhereClause = ''

			if charindex('where', @cBufferContents) > 0
			begin
				set @cWhereClause = substring(@cBufferContents, charindex('WHERE', @cBufferContents), 500)
				set @cWhereClause = replace(replace(replace(@cWhereClause, char(13), '~~'), char(10), '~~'), char(9), '~~')
				set @cWhereClause = replace(@cWhereClause, ' and', '~~and')
				set @cWhereClause = replace(@cWhereClause, ' or', '~~or')

				declare @whereClause table (token varchar(1000))

				insert into @whereClause (token)
				select listItem from dbo.fn_makeTableFromList(@cWhereClause, '~~')

				update @whereClause set token = left(token, charindex('=', token)) + '= XXX' where charindex('=', token) > 0
				update @whereClause set token = left(token, charindex('in', token)) + 'in XXX' where token like ' in%(' and charindex('charindex', token) = 0
				update @whereClause set token = left(token, charindex('like', token)) + 'like XXX' where charindex('like', token) > 0

				set @cWhereClause = ''
				select @cWhereClause = @cWhereClause + token + space(1) from @whereClause
			end

			set @cReturnString = left(
				case
					when @cBufferContents like '%select[ ]%from[ ]%where[ ]%'
							and (charindex('where ', @cBufferContents) - charindex('from ', @cBufferContents) - 6) >= 0
						then 'SELECT ... ' +
							'FROM ' + substring(@cBufferContents, charindex('from ', @cBufferContents) + 5, charindex('where ', @cBufferContents) - charindex('from ', @cBufferContents) - 6) + ' ' +
							isnull(@cWhereClause, 'WHERE ...')
					when @cBufferContents like '%select[ ]%from[ ]%'
						then 'SELECT ... FROM ' + substring(@cBufferContents, charindex('from ', @cBufferContents) + 5, 500)
					when @cBufferContents like '%update[ ]%set[ ]%where[ ]%'
						then left(
							substring(@cBufferContents, charindex('update', @cBufferContents), 500), charindex('SET', substring(@cBufferContents, charindex('update', @cBufferContents), 500)) -1 ) + ' ' +
								'SET ... ' +
								isnull(@cWhereClause, 'WHERE ...')
					when @cBufferContents like '%update[ ]%set[ ]%'
						then left(substring(@cBufferContents, charindex('update', @cBufferContents), 500), charindex('SET', substring(@cBufferContents, charindex('update', @cBufferContents), 500)) -1 ) + ' SET ... '
					else @cBufferContents
					end, 500)

			if dbo.fn_occurs(space(1), @cReturnString) = 1 and left(@cReturnString, 4) <> 'exec'
				set @cReturnString = left(@cReturnString, charindex(space(1), @cReturnString))
		end
	end

--	if charindex('"', @cReturnString) > 1
--		set @cReturnString = left(@cReturnString, charindex('"', @cReturnString) - 1)
	if charindex('@', @cReturnString) > 1 and charindex('@@', @cReturnString) = 0
		set @cReturnString = left(@cReturnString, charindex('@', @cReturnString) - 1)

--	set @cReturnString = convert(varchar(20), @nTrimCounter) + @cPrepend + @cReturnString

	if left(@cReturnString, 4) = 'dbo.'
		set @cReturnString = substring(@cReturnString, 5, 500)

	if @cReturnString in ('begin', 'select', '(', 'begin tran')
		set @cReturnString = @cBufferContents

	set @cReturnString = (select dbo.fn_returnFormattedBuffer(@cReturnString))

	return @cReturnString
end

-- select dbo.fn_returnTrimmedBuffer('create function fn_trjisdf(')
GO
