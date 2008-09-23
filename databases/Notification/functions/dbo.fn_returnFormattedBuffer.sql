create function dbo.fn_returnFormattedBuffer (@cBuffer varchar(8000))
returns varchar(8000)
as
begin
	declare @cReturnString varchar(8000)

	set @cReturnString = replace(replace(
			left(case
				when @cBuffer like '%fetch%cursor%' then 'CURSOR'
				when @cBuffer like '%Transactions_PurgeByDays%' then 'Daily Purge'
				else @cBuffer end, 500),
			char(13), '<br>'),
			'|', ''
			)

	return @cReturnString
end
