SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from AppDb.dbo.websites
-- exec pr_admin_rpt_websiteSummary 'cole', '', '', 48
ALTER procedure [dbo].[pr_admin_rpt_websiteSummary] (@cToken varchar(100), @cSessionID varchar(100), @cMachineID varchar(100), @nUkeyWebsite int = 0)
as
begin

	declare @nUkeyUser int
	declare @dStartDate dateTime

	select @nUkeyUser = ukey_user
		from dbo.fn_admin_validateCredentials(@cToken)

	if @nUkeyWebsite <> 0 and @nUkeyWebsite not in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser)
		return

	if @nUkeyUser is null
	begin
		return
	end

	set @dStartDate = isnull(@dStartDate, dateAdd(hour, -30*24, getDate()))

--select top 10 * from mart_site_byday

	select
		dbo.fn_returnFormattedDecimal(projectedTotal) as dollars_next30,
		dbo.fn_returnFormattedDecimal(c.amount_total) as dollars_last30,
		dbo.fn_returnFormattedDecimal(d.amount_total) as dollars_ytd,
		dbo.fn_returnFormattedDecimal(e.amount_total) as dollars_lastMonth,

		dbo.fn_returnFormattedInt(projectedOrders) as orders_next30,
		dbo.fn_returnFormattedInt(c.numOrders) as orders_last30,
		dbo.fn_returnFormattedInt(d.numOrders) as orders_ytd,
		dbo.fn_returnFormattedInt(e.numOrders) as orders_lastMonth
		from (
			select
				sum(totalPurchased) as amount_total,
				sum(purchases) as numOrders
				from mart_site_byday a (nolock)
				where a.ymd >= dateAdd(day, -14, convert(varchar(10), getDate(), 120))
					and a.ymd <= dateAdd(day, 1, convert(varchar(10), getDate(), 120))
					and a.ukey_website in (select distinct ukey_website from AppDb.dbo.websiteUserAccess where ukey_user = @nUkeyUser)
					and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			) a, (
			select count(distinct ymd) as numDays
				from mart_site_byday a (nolock)
				where ymd >= dateAdd(day, -14, convert(varchar(10), getDate(), 120))
					and ymd < dateAdd(day, 1, convert(varchar(10), getDate(), 120))
					and ukey_website in (select distinct ukey_website from AppDb.dbo.websiteUserAccess where ukey_user = @nUkeyUser)
					and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			) b, (
			select
				sum(totalPurchased) as amount_total,
				sum(purchases) as numOrders
				from mart_site_byday a (nolock)
				where a.ymd >= @dStartDate
					and a.ukey_website in (select distinct ukey_website from AppDb.dbo.websiteUserAccess where ukey_user = @nUkeyUser)
					and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			) c, (
			select
				sum(totalPurchased) as amount_total,
				sum(purchases) as numOrders
				from mart_site_byday a (nolock)
				where datePart(year, ymd) = datePart(year, getDate())
					and a.ukey_website in (select distinct ukey_website from AppDb.dbo.websiteUserAccess where ukey_user = @nUkeyUser)
					and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			) d, (
			select
				sum(totalPurchased) as amount_total,
				sum(purchases) as numOrders
				from mart_site_byday (nolock) a
				where datePart(year, ymd) = datePart(year, dateAdd(month, -1, getDate()))
					and datePart(month, ymd) = datePart(month, dateAdd(month, -1, getDate()))
					and ukey_website in (select distinct ukey_website from AppDb.dbo.websiteUserAccess where ukey_user = @nUkeyUser)
					and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
			) e, (
				select
					case when numDays = 0 then 0 else (amount_total/numDays) * 30 end as projectedTotal,
					case when numDays = 0 then 0 else (numOrders/numDays) * 30 end as projectedOrders
					from (
						select
							sum(amount_total) as amount_total,
							count(*) as numOrders
							from orderHeader a (nolock)
							where isnull(cancelled, 0) = 0
								and a.confirmedPayment is not null
								and a.ymd >= dateAdd(day, -10, convert(varchar(10), getDate(), 120))
								and a.ymd < dateAdd(day, 1, convert(varchar(10), getDate(), 120))
								and ukey_website in (select distinct ukey_website from AppDb.dbo.websiteUserAccess where ukey_user = @nUkeyUser)
								and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
						) a,
					(
						select count(distinct ymd) as numDays
							from mart_site_byday a (nolock)
							where ymd >= dateAdd(day, -10, convert(varchar(10), getDate(), 120))
								and ymd < dateAdd(day, 1, convert(varchar(10), getDate(), 120))
								and ukey_website in (select distinct ukey_website from AppDb.dbo.websiteUserAccess where ukey_user = @nUkeyUser)
								and (a.ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0)
						) b

				) f

end
