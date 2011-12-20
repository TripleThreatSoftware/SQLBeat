USE [notification]
GO
/****** Object:  StoredProcedure [dbo].[pr_rpt_recompiledObjects]    Script Date: 12/20/2011 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec pr_rpt_recompiledObjects 'funmssql02', null, null
ALTER procedure [dbo].[pr_rpt_recompiledObjects] (@cServerName varchar(100), @nNumHours int = 6)
as
begin

	select
		convert(decimal(10,2), left(a.subkeyName, charindex(' ', a.subkeyName))) as [Plans Per Hour],
		left(keyValue, len(keyValue) - 1) as [Object Name]
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
		order by convert(decimal(10,2), left(a.subkeyName, charindex(' ', a.subkeyName))) desc



end
