/****** Object:  Trigger [dbo].[trg_securityEventIds_updated]    Script Date: 11/6/2026 9:52:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE trigger [dbo].[trg_securityEventIds_updated] on [dbo].[securityEventIds] for update
as
begin
	update a
	set ymd_modified = getdate(),
	whoDidIt = suser_sname()
	from securityEventIds a
	join inserted b on a.ukey = b.ukey
end
GO
