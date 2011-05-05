create procedure pr_maintainWebsitePartnerCPC
as
begin

	declare @nUkeyWebsite int
	set @nUkeyWebsite = 0

	if exists (select top 1 [name] from sysobjects where [name] = 'lk_websitePartnerCPC_byday_stage')
		drop table lk_websitePartnerCPC_byday_stage

	if exists (select top 1 [name] from sysobjects where [name] = 'lk_websitePartnerCPC_byday_old')
		drop table lk_websitePartnerCPC_byday_old

	create table lk_websitePartnerCPC_byday_stage (ukey_website int, partner varchar(100), cpc decimal(10,4), ymd dateTime)

	while exists (select top 1 ukey from AppDb.dbo.websites (nolock) where ukey > @nUkeyWebsite and enabled = 1)
	begin
		select top 1 @nUkeyWebsite = ukey
			from AppDb.dbo.websites (nolock)
			where ukey > @nUkeyWebsite
				 and enabled = 1
			order by ukey

		insert into lk_websitePartnerCPC_byday_stage
		select @nUkeyWebsite, *
			from AppDb.dbo.fn_returnCPCByDay(@nUkeyWebsite)
	end

	create clustered index ix_websitePartnerCPCByDay_cpc on lk_websitePartnerCPC_byday_stage (ukey_website, partner, ymd) with fillfactor = 100

	begin transaction swapTables
		exec sp_rename 'lk_websitePartnerCPC_byday', 'lk_websitePartnerCPC_byday_old'
		exec sp_rename 'lk_websitePartnerCPC_byday_stage', 'lk_websitePartnerCPC_byday'
	commit transaction swapTables

end
GO
