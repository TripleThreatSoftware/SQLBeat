SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_admin_rpt_partnerDetailedPerformance 'cole', '', '', null, null, 41
-- select * from websiteUsers
ALTER procedure [dbo].[pr_admin_rpt_partnerDetailedPerformance] (@cToken varchar(100), @cSessionID varchar(100), @cMachineID varchar(100),
	@dStartDate dateTime = null, @dEndDate dateTime = null, @nUkeyWebsite int = 0)
as
begin
--	set @nDays = 300


	declare @nUkeyUser int
	declare @nUkey int

	select @nUkeyUser = ukey_user
		from dbo.fn_admin_validateCredentials(@cToken)

	if @nUkeyWebsite <> 0 and @nUkeyWebsite not in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser)
		return

	if @nUkeyUser is null
	begin
		return
	end

	exec pr_admin_recordAction @cToken, @cSessionID, @cMachineID, 'Show partner detailed performance '

	if isnull(@dStartDate, '') = ''
		set @dStartDate = dateAdd(day, -7*10, getDate())

	if isnull(@dEndDate, '') = ''
		set @dEndDate = (select max(ymd) from mart_sessions_byday)


	select
		case when charindex('%', a.partner) > 0 then left(a.partner, charindex('%', a.partner) - 1) else a.partner end as [Partner],
		a.numUsers as [Visitors],
		convert(decimal(10,2), a.productConversion) as [Product C/R],
		case when numUsers = 0 then 0 else isnull(convert(decimal(10,2), 100 * convert(decimal(20,6), isnull(b.purchases, 0)) / convert(decimal(20,6), numUsers)), 0) end as [C/R],
		convert(decimal(10,2), isnull(b.basketSize, 0)) as Basket,
		isnull(b.purchases, 0) as Sales,
		isnull(a.cost, 0) as Spent,
		convert(decimal(10,2), case when isnull(a.payableClicks, 0) = 0 then 0 else isnull(a.cost, 0) / isnull(a.payableClicks, 0) end) as CPC,
		case when isnull(b.purchases, 0) = 0 then 0 else convert(decimal(10,2), isnull(a.cost, 0) / convert(decimal(10,2), isnull(b.purchases, 0))) end as CPA,
		case when isnull(b.purchases, 0) = 0 then 0 else convert(decimal(10,2), isnull(income, 0) / convert(decimal(10,2), isnull(b.purchases, 0))) end as [GP/Sale],
		case when isnull(b.purchases, 0) = 0 then 0 else convert(decimal(10,2), (isnull(income, 0) - isnull(cost, 0)) / convert(decimal(10,2), isnull(b.purchases, 0))) end as [Net/Sale],

		convert(decimal(10,2), isnull(income, 0) - isnull(cost, 0)) as [Net Profit]

		from (

			select
				a.runningpartner as partner,

				count(distinct sessionID) as numSessions,
				count(distinct machineID) as numUsers,

				count(distinct case when isnull(a.partner, '') <> '' then machineID else null end) as payableClicks,
				convert(decimal(10,2), sum(case when isnull(a.partner, '') <> '' then isnull(b.cpc, 0) else null end)) as cost,

				count(distinct a.sessionID) - count(distinct a.machineID) as returningUsers,
				convert(decimal(10,2), avg(convert(decimal(10,2), productViews))) as avgProductViews,
				sum(productViews) as productViews,
				sum(productSearches) as productSearches,
				count(distinct case when cartViews > 0 then a.sessionID else null end) as cartViews,

				convert(decimal(10,4), 100 * case when count(distinct case when productViews > 0 then a.sessionID else null end) = 0 then 0 else convert(decimal(20,6), count(distinct case when productViews > 0 then a.sessionID else null end)) / convert(decimal(20,6), count(*)) end) as productConversion,
				convert(decimal(10,4), 100 * case when count(distinct case when productSearches > 0 then a.sessionID else null end) = 0 then 0 else convert(decimal(20,6), count(distinct case when productSearches > 0 then a.sessionID else null end)) / convert(decimal(20,6), count(*)) end) as searchConversion,

				convert(decimal(10,4), 100 * convert(decimal(20,6), count(distinct case when cartViews > 0 then sessionID else null end)) / convert(decimal(20,6), count(distinct a.sessionID)))  as cartConversion

				from mart_sessions a (nolock)
				left outer join lk_websitePartnerCPC_byday b on a.partner = b.partner
					and convert(varchar(10), a.ymd, 120) = b.ymd
					and a.ukey_website = b.ukey_website
				where a.ymd >= dateAdd(day, -30, convert(varchar(10), getDate(), 120))
					and a.ukey_website in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))
				group by a.runningpartner


			) a
		left outer join (
			select
				c.runningpartner as partner,
				isnull(sum((isnull(a.amount_total, 0) - isnull(a.amount_tax, 0)) * (d.grossProfitPercent / 100.00)), 0) as income,
				sum((isnull(a.amount_total, 0))) as totalPurchased,
				sum((isnull(abs(a.amount_discount), 0))) as totalDiscount,
				sum((isnull(a.amount_parts, 0))) as totalParts,
				sum((isnull(a.amount_shipping, 0))) as totalShipping,
				sum(isnull(case when a.orderStatus like '%shipped%' then isnull(a.amount_total, 0) else 0 end, 0)) as totalShipped,
				sum(isnull(case when a.orderStatus not like '%shipped%' then isnull(a.amount_total, 0) else 0 end, 0)) as totalUnShipped,
				isnull(avg(isnull(a.amount_parts, 0)), 0) as basketSize,
				count(distinct a.ukey) as purchases

				from orderHeader a (nolock)
				join mart_sessions c (nolock) on a.sessionID = c.sessionID
					and a.machineID = c.machineID
					and a.ukey_website = c.ukey_website
					and c.ukey_website in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))
				join websites d (nolock) on a.ukey_website = d.ukey
				where isnull(a.cancelled, 1) <> 1
					and isnull(a.confirmedPayment, '') <> ''
					and a.ymd >= dateAdd(day, -30, convert(varchar(10), getDate(), 120))
					and a.ukey_website in (select distinct ukey_website from websiteUserAccess where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))

				group by c.runningpartner
			) b on a.partner = b.partner
		where a.partner not in ('googlebase', 'Google Base', 'Google Search', 'Yahoo Search', 'MSN Live Search', 'Live Search', 'AOL', 'Bing Search', 'Bing Shopping')
			and isnull(a.partner, '') <> ''
			and a.numUsers >= 5
		order by isnull(income, 0) - isnull(cost, 0) desc

end
