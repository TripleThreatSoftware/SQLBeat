/****** Object:  StoredProcedure [dbo].[pr_rpt_recompiledObjects]    Script Date: 05/07/2009 10:30:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_recompiledObjects 'funmssql02', null, null
CREATE procedure [dbo].[pr_rpt_recompiledObjects] (@cServerName varchar(100), @nNumHours int = 6)
as
begin

	select left(a.subkeyName, charindex(' ', a.subkeyName)) as subkeyName, left(keyValue, len(keyValue) - 1) as keyValue
		from (
			select left(keyValue, charindex('for "', keyValue) - 1) as subkeyName,
				substring(keyValue, charindex('"', keyValue) + 1, 8000) as keyValue,
				ymd
				from deepSQLStats (nolock)
				where serverName = @cServerName
					and keyName = 'Recompiled objects'
					and ymd >= dateAdd(hour, -@nNumHours, getDate())
					and keyValue not like '%veryUsedIndexes%'
			) a
--		left outer join (
--			select distinct left(bufferContents, 100) as buffer
--				from processLog (nolock)
--				where serverName = @cServerName
--					and hostname = @@servername
--					and ymd >= dateAdd(hour, -@nNumHours, getDate())
--					and bufferContents is not null
--			) b on replace(a.keyValue, space(1), space(0)) like '%' + replace(b.buffer, space(1), space(0)) + '%'
		where
--			b.buffer is null and
			not (a.keyValue like '%publisher%' and a.keyValue like '%latestData%')
			and not a.keyValue like '%pr_backupDatabase%'
			and not a.keyValue like '%sysjob%'
			and charindex('|||', a.keyValue) = 0
		order by subkeyName



end
GO
