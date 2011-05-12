SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from websiteUsers
-- exec pr_admin_rpt_siteSummary 'cole', '', '', null, null, 13
ALTER procedure [dbo].[pr_admin_rpt_siteSummary] (@cToken varchar(100), @cSessionID varchar(100), @cMachineID varchar(100),
	@dStartDate dateTime = null, @dEndDate dateTime = null, @nUkeyWebsite int = 0)
as
begin

	declare @nUkeyUser int
print convert(varchar(20), getDate(), 120)

	select @nUkeyUser = ukey_user
		from dbo.fn_admin_validateCredentials(@cToken)

	if @nUkeyWebsite <> 0 and @nUkeyWebsite not in (select distinct ukey_website from websiteUserAccess (nolock) where ukey_user = @nUkeyUser)
		return

	if @nUkeyUser is null
		return

	set @dStartDate = isnull(@dStartDate, dateAdd(week, -3, getDate()))
	set @dEndDate = isnull(@dEndDate, getDate())

	exec pr_admin_recordAction @cToken, @cSessionID, @cMachineID, 'Site summary'

print convert(varchar(20), getDate(), 120)

	create table #results (ukey int identity, keyName varchar(200), keyValue varchar(200))

	select *
		into #data
		from siteStatisticsSnapshot (nolock)
		where ukey_website in (select distinct ukey_website from websiteUserAccess (nolock) where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))


print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Daily Visitors', convert(varchar(20), sum(uniquesPerDay))
		from #data

	insert into #results (keyName, keyValue)
	select 'Daily Pageviews', convert(varchar(20), sum(pageviewsPerDay))
		from #data

	insert into #results (keyName, keyValue)
	select 'Daily Product Views', convert(varchar(20), sum(productViewsPerDay))
		from #data

print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Number of Products' , sum(numProducts)
		from #data

print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Average product views', convert(varchar(20), convert(decimal(10,2), sum(productViews*numUsers)/sum(numUsers)))
		from #data

	insert into #results (keyName, keyValue)
	select 'Compound product views', convert(varchar(20), convert(decimal(10,2), sum(productViews_viewing*numUsers)/sum(numUsers)))
		from #data

	insert into #results (keyName, keyValue)
	select 'Average page views', convert(varchar(20), convert(decimal(10,2), sum(pageViews*numUsers)/sum(numUsers)))
		from #data

	insert into #results (keyName, keyValue)
	select 'Minutes on site', convert(varchar(20), convert(decimal(10,2), sum(minutesOnSite*numUsers)/sum(numUsers)))
		from #data

	insert into #results (keyName, keyValue)
	select 'Product Conversion', convert(varchar(20), convert(decimal(10,2), 100*convert(decimal(10,2), sum(usersFindingProducts)) / convert(decimal(10,2), sum(numUsers)))) + ' %'
		from #data

	insert into #results (keyName, keyValue)
	select '3 Week Conversion', convert(varchar(20), convert(decimal(10,2), 100*convert(decimal(10,2), sum(numOrders)) / convert(decimal(10,2), sum(numUsers)))) + ' %'
		from #data

	if (select sum(numUsers_week1) from #data) > 0
	begin
		insert into #results (keyName, keyValue)
		select '1 Week Conversion', convert(varchar(20), convert(decimal(10,2), 100*convert(decimal(10,2), sum(numOrders_week1)) / convert(decimal(10,2), sum(numUsers_week1)))) + ' %'
			from #data
	end

print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Search Time', convert(varchar(20), sum(searchTime*numSearches)/sum(numSearches)) + ' ms'
		from #data
		having sum(numSearches) > 0

print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Search Suggestion Time' , convert(varchar(20), sum(searchSuggestionTime*numSearchSuggestions)/sum(numSearchSuggestions)) + ' ms'
		from #data
		having sum(numSearchSuggestions) > 0

print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Product Suggestion Time' , convert(varchar(20), sum(suggestionTime*numSuggestedProductLookups)/sum(numSuggestedProductLookups)) + ' ms'
		from #data
		having sum(numSuggestedProductLookups) > 0

print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Search Interpretation Time' , convert(varchar(20), sum(searchInterpretTime*numSummarizedSearches)/sum(numSummarizedSearches)) + ' ms'
		from #data
		having sum(numSummarizedSearches) > 0

print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Searches Per Minute' , convert(varchar(20), convert(decimal(10,2), sum(searchesPerMinute)))
		from #data

print convert(varchar(20), getDate(), 120)

	insert into #results (keyName, keyValue)
	select 'Product Views Per Minute' , convert(varchar(20), convert(decimal(10,2), sum(productViewsPerMinute)))
		from #data

	insert into #results (keyName, keyValue)
	select 'PageViews Per Minute' , convert(varchar(20), convert(decimal(10,2), sum(pageViewsPerMinute)))
		from #data


	insert into #results (keyName, keyValue)
	select 'Average Daily Parts Sold' , '$ ' + convert(varchar(20), convert(decimal(10,2), sum(amount_parts_avg)))
		from #data

	insert into #results (keyName, keyValue)
	select 'Average Daily Receipts' , '$ ' + convert(varchar(20), convert(decimal(10,2), sum(amount_total_avg)))
		from #data

	insert into #results (keyName, keyValue)
	select 'Projected 30 Day Parts Sold' , '$ ' + convert(varchar(20), convert(decimal(10,2), sum(projectedParts)))
		from #data

	insert into #results (keyName, keyValue)
	select 'Projected 30 Day Receipts' , '$ ' + convert(varchar(20), convert(decimal(10,2), sum(projectedTotal)))
		from #data

	if (select sum(numOrders) from #data) > 0
	begin
		insert into #results (keyName, keyValue)
		select 'CPA' , '$ ' + convert(varchar(20), convert(decimal(10,2), convert(decimal(10,2), sum(cost)) / convert(decimal(10,2), sum(numOrders))))
			from #data
	end

	insert into #results (keyName, keyValue)
	select 'Pending Orders', count(*)
		from orderHeader (nolock)
		where cancelled <> 1
			and confirmedPayment is not null
			and orderStatus not like '%shipped%'
			and orderStatus not like '%exception%'
			and ukey_website in (select distinct ukey_website from websiteUserAccess (nolock) where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))


	insert into #results (keyName, keyValue)
	select 'Exception Orders', count(*)
		from orderHeader (nolock)
		where cancelled <> 1
			and confirmedPayment is not null
			and orderStatus not like '%shipped%'
			and orderStatus not like '%exception%'
			and isException = 1
			and ukey_website in (select distinct ukey_website from websiteUserAccess (nolock) where ukey_user = @nUkeyUser and (ukey_website = @nUkeyWebsite or isnull(@nUkeyWebsite, 0) = 0))


print convert(varchar(20), getDate(), 120)

	select * from #results order by ukey

	drop table #data
	drop table #results
end
