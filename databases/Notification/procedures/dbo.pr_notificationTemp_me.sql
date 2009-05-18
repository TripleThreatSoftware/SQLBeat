/****** Object:  StoredProcedure [dbo].[pr_notificationTemp_me]    Script Date: 05/19/2009 13:59:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pr_notificationTemp_me]
				as
				begin
					insert into #lockresults
					select name
						from [tempdb].dbo.sysobjects
						where id = 1228828852
				end
GO
