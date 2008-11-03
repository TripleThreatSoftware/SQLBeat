				create procedure pr_notificationTemp_me
				as
				begin
					insert into #lockresults
					select name
						from [tempdb].dbo.sysobjects
						where id = 1578592812
				end



GO
