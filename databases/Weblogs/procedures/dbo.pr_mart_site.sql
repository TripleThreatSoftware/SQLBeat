SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_mart_site 5

ALTER procedure [dbo].[pr_mart_site] (@nNumDays int = 30)
as
begin

	declare @nUkeyWebsite int
	set @nUkeyWebsite = 0

	select
		a.*,

		isnull(income, 0) - isnull(cost, 0) as net,
		convert(decimal(10,2), 100 * convert(decimal(20,6), isnull(b.purchases, 0)) / convert(decimal(20,6), numUsers)) as conversionRate,
		isnull(b.income, 0) as income,
		isnull(b.totalPurchased, 0) as totalPurchased,
		isnull(b.totalDiscount, 0) as totalDiscount,
		isnull(b.totalParts, 0) as totalParts,
		isnull(b.totalShipping, 0) as totalShipping,
		isnull(b.totalShipped, 0) as totalShipped,
		isnull(b.totalUnshipped, 0) as totalUnshipped,
		isnull(b.basketSize, 0) as basketSize,
		isnull(b.purchases, 0) as purchases

		into #mart_site

		from (
			select
				a.ukey_website, convert(varchar(10), a.ymd, 120) as ymd,

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

				where a.ymd >= dateAdd(day, -@nNumDays, convert(varchar(10), getDate(), 120))
				group by a.ukey_website,
					convert(varchar(10), a.ymd, 120)

			) a
		left outer join (
			select
				a.ukey_website,
				convert(varchar(10), a.ymd, 120) as ymd,
				isnull(sum((isnull(a.amount_total, 0) - isnull(a.amount_tax, 0)) * (d.grossProfitPercent / 100.00)), 0) as income,
				sum((isnull(a.amount_total, 0))) as totalPurchased,
				sum((isnull(abs(a.amount_discount), 0))) as totalDiscount,
				sum((isnull(a.amount_parts, 0))) as totalParts,
				sum((isnull(a.amount_shipping, 0))) as totalShipping,
				sum(isnull(case when a.orderStatus like '%shipped%' then isnull(a.amount_total, 0) else 0 end, 0)) as totalShipped,
				sum(isnull(case when a.orderStatus not like '%shipped%' and a.orderStatus not like '%exception%' then isnull(a.amount_total, 0) else 0 end, 0)) as totalUnShipped,
				isnull(avg(isnull(a.amount_parts, 0)), 0) as basketSize,
				count(distinct a.ukey) as purchases

				from orderHeader a (nolock)
				join mart_sessions c (nolock) on a.sessionID = c.sessionID
					and a.machineID = c.machineID
					and a.ukey_website = c.ukey_website
				join websites d (nolock) on a.ukey_website = d.ukey
				where isnull(a.cancelled, 1) <> 1
					and isnull(a.confirmedPayment, '') <> ''
					and a.ymd >= dateAdd(day, -@nNumDays, convert(varchar(10), getDate(), 120))

				group by a.ukey_website, convert(varchar(10), a.ymd, 120)
			) b on a.ymd = b.ymd
				and a.ukey_website = b.ukey_website
		option (maxdop 3)

	delete mart_site_byday with (rowlock)
		from mart_site_byday a
		join #mart_site b on a.ukey_website = b.ukey_website
			and convert(varchar(10), a.ymd, 120) = convert(varchar(10), b.ymd, 120)

	insert into mart_site_byday ([ukey_website]
      ,[ymd]
      ,[numSessions]
      ,[numUsers]
      ,[cost]
      ,[returningUsers]
      ,[avgProductViews]
      ,[productViews]
      ,[productSearches]
      ,[cartViews]
      ,[productConversion]
      ,[searchConversion]
      ,[cartConversion]
      ,[net]
      ,[conversionRate]
      ,[income]
      ,[totalPurchased]
      ,[totalDiscount]
      ,[totalParts]
      ,[totalShipping]
      ,[totalShipped]
      ,[totalUnshipped]
      ,[basketSize]
      ,[purchases], payableClicks)
	select [ukey_website]
      ,[ymd]
      ,[numSessions]
      ,[numUsers]
      ,[cost]
      ,[returningUsers]
      ,[avgProductViews]
      ,[productViews]
      ,[productSearches]
      ,[cartViews]
      ,[productConversion]
      ,[searchConversion]
      ,[cartConversion]
      ,[net]
      ,[conversionRate]
      ,[income]
      ,[totalPurchased]
      ,[totalDiscount]
      ,[totalParts]
      ,[totalShipping]
      ,[totalShipped]
      ,[totalUnshipped]
      ,[basketSize]
      ,[purchases], payableClicks
		from #mart_site

	drop table #mart_site

end

---- prime
--select *, identity(int) as ukey
--	into mart_partner_byday
--	from #mart_partner
--
--select *, identity(int) as ukey
--	into mart_site_byday
--	from #mart_site
--
--go
--

--create clustered index ix_martPartner_website_ymd_partner on mart_partner_byday (ukey_website, ymd, partner, ukey) with fillfactor = 70
--go
--create clustered index ix_martSize_website_ymd on mart_site_byday (ukey_website, ymd, ukey) with fillfactor = 70
--go
