SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_maintainMakeProducts]
as
begin

	if exists (select top 1 [name] from sysobjects where [name] = 'lk_makeProducts_stage')
		drop table lk_makeProducts_stage
	if exists (select top 1 [name] from sysobjects where [name] = 'lk_makeProducts_old')
		drop table lk_makeProducts_old

	select distinct a.ukey_website, b.ukey_make, a.ukey_product
		into lk_makeProducts_stage
		from productFitment a (nolock)
		join dm_fitment b (nolock) on a.ukey_fitment = b.ukey
			and a.ukey_website = b.ukey_website

	create clustered index ix_makeProducts_website_make_product on lk_makeProducts_stage (ukey_website, ukey_make, ukey_product) with fillfactor = 80

	begin transaction swapTables
		exec sp_rename 'lk_makeProducts', 'lk_makeProducts_old'
		exec sp_rename 'lk_makeProducts_stage', 'lk_makeProducts'
	commit transaction swapTables

	if exists (select top 1 [name] from sysobjects where [name] = 'lk_makeProducts_old')
		drop table lk_makeProducts_old
end
