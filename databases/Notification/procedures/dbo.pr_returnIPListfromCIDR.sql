/****** Object:  StoredProcedure [dbo].[pr_returnIPListfromCIDR]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_returnIPListfromCIDR '139.87.113.10', 8
-- exec pr_returnIPListfromCIDR '139.87.113.10', 32
-- exec pr_returnIPListfromCIDR '139.87.112.0', 23
CREATE procedure [dbo].[pr_returnIPListfromCIDR] (@cIPAddress varchar(15), @nSubnet int)
as
begin
	declare @cLowRange varchar(16)
	declare @cHighRange varchar(16)
	declare @nAddressQty int
	declare @nOct1 int
	declare @nOct2 int
	declare @nOct3 int
	declare @nOct4 int
	declare @nMinOct1 int
	declare @nMinOct2 int
	declare @nMinOct3 int
	declare @nMinOct4 int
	declare @nMaxOct1 int
	declare @nMaxOct2 int
	declare @nMaxOct3 int
	declare @nMaxOct4 int
	declare @nDiffOct1 int
	declare @nDiffOct2 int
	declare @nDiffOct3 int
	declare @nDiffOct4 int
	declare @nCount int

	create table #ipAddressList (ukey int identity, ipAddress varchar(15), oct1 int, oct2 int, oct3 int, oct4 int)

	if isnull(@nSubnet, 0) < 16
	begin
		select top 0 ipAddress from #ipAddressList

		print '***Subnet Mask is too low for this current method. Needs to be 16+***'

		drop table #ipAddressList

		return
	end

	select top 1
		@cLowRange = a.LowRange,
		@cHighRange = a.HighRange,
		@nAddressQty = a.addressQty
		from [Notification].[dbo].[fn_getCidrIpAddressRange](@cIPAddress, @nSubnet) as a

	--select
	--	@cLowRange,
	--	@cHighRange,
	--	@nAddressQty

	set @nMinOct1 = [Notification].[dbo].[fn_returnListItem](@cLowRange, 1, '.')
	set @nMinOct2 = [Notification].[dbo].[fn_returnListItem](@cLowRange, 2, '.')
	set @nMinOct3 = [Notification].[dbo].[fn_returnListItem](@cLowRange, 3, '.')
	set @nMinOct4 = [Notification].[dbo].[fn_returnListItem](@cLowRange, 4, '.')

	set @nMaxOct1 = [Notification].[dbo].[fn_returnListItem](@cHighRange, 1, '.')
	set @nMaxOct2 = [Notification].[dbo].[fn_returnListItem](@cHighRange, 2, '.')
	set @nMaxOct3 = [Notification].[dbo].[fn_returnListItem](@cHighRange, 3, '.')
	set @nMaxOct4 = [Notification].[dbo].[fn_returnListItem](@cHighRange, 4, '.')

	set @nDiffOct1 = @nMaxOct1 - @nMinOct1
	set @nDiffOct2 = @nMaxOct2 - @nMinOct2
	set @nDiffOct3 = @nMaxOct3 - @nMinOct3
	set @nDiffOct4 = @nMaxOct4 - @nMinOct4

	set @nOct1 = @nMinOct1
	set @nOct2 = @nMinOct2
	set @nOct3 = @nMinOct3
	set @nOct4 = @nMinOct4

	--select @nDiffOct1, @nDiffOct2, @nDiffOct3, @nDiffOct4

	insert into #ipAddressList (ipAddress, oct1, oct2, oct3, oct4)
	values (@cLowRange, @nMinOct1, @nMinOct2, @nMinOct3, @nMinOct4)

	set @nCount = 0

	if @nDiffOct1 = 0 and @nDiffOct2 = 0 and @nDiffOct3 > 0
	begin
		while @nCount < @nAddressQty -1
		begin
			if (@nOct3 < @nMaxOct3 and @nOct4 < 255)
				or (@nOct3 = @nMaxOct3 and @nOct4 < @nMaxOct4)
			begin
				set @nOct4 = @nOct4 + 1
			end
			else
			if @nOct3 < @nMaxOct3
				and @nOct4 = 255
			begin
				set @nOct3 = @nOct3 + 1
				set @nOct4 = 0
			end

			insert into #ipAddressList (ipAddress, oct1, oct2, oct3, oct4)
			values (convert(varchar(3), @nOct1) + '.' +
						convert(varchar(3), @nOct2) + '.' +
						convert(varchar(3), @nOct3) + '.' +
						convert(varchar(3), @nOct4),
					@nOct1, @nOct2, @nOct3, @nOct4)

			set @nCount = @nCount + 1

		end
	end

	if @nDiffOct1 = 0 and @nDiffOct2 = 0 and @nDiffOct3 = 0 and @nDiffOct4 > 0
	begin
		while @nCount < @nDiffOct4
		begin
			set @nOct4 = @nOct4 + 1

			insert into #ipAddressList (ipAddress, oct1, oct2, oct3, oct4)
			values (convert(varchar(3), @nOct1) + '.' +
						convert(varchar(3), @nOct2) + '.' +
						convert(varchar(3), @nOct3) + '.' +
						convert(varchar(3), @nOct4),
					@nOct1, @nOct2, @nOct3, @nOct4)

			set @nCount = @nCount + 1
		end
	end

--	select * from #ipAddressList
	select ipAddress from #ipAddressList

	drop table #ipAddressList

end
GO
