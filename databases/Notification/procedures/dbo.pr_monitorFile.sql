-- exec pr_monitorFile '\\appapps02\c$\AppServices\UnisonFolderSync\unisonFileSync.log', 'Error', 'appapps02'
create procedure [pr_monitorFile] (@cFileToMonitor varchar(500), @cStringToFind varchar(100), @cServerName varchar(200))
as
begin

	--declare @cFileToMonitor varchar(500)
	--declare @cStringToFind varchar(100)
	--declare @cServerName varchar(200)
	--set @cServerName = 'appapps02'
	--set @cFileToMonitor = '\\appapps02\c$\AppServices\UnisonFolderSync\unisonFileSync.log'
	--set @cStringToFind = 'Error'

	set nocount on

	declare @cSQLString nvarchar(4000)
	declare @cSubject varchar(500)
	declare @cMessage varchar(8000)
	declare @nLineNumber bigint

	create table ##fileMonitor (fileLine varchar(8000))

	create table #results (resultLine varchar(8000))
	truncate table ##fileMonitor

			set @cSQLString = '
				bulk insert ##fileMonitor
					from ''' + @cFileToMonitor + '''
					WITH
					(
						FIRSTROW = 1,
						ROWTERMINATOR =''\n'',
						MAXERRORS = 1000
					)'

			truncate table #results

			begin try
				insert into #results (resultLine)
				exec sp_executeSQL @cSQLString
			end try
			begin catch
				select error_message()
			end catch

	select *, identity(int) as lineNumber
		into #fileData
		from ##fileMonitor

	select *
		into #linesFound
		from #fileData
		where fileLine like '%' + @cStringToFind + '%'

	set @nLineNumber = 0

	while exists (select top 1 lineNumber from #linesFound where lineNumber > @nLineNumber)
	begin
		select top 1 @nLineNumber = lineNumber
			from #linesFound
			where lineNumber > @nLineNumber
			order by lineNumber

		set @cSubject = 'String "' + @cStringToFind + '" found in "' + @cFileToMonitor + '" at line ' + convert(varchar(20), @nLineNumber)

		set @cMessage = 'String "' + @cStringToFind + '" found in "' + @cFileToMonitor + '" at line ' + convert(varchar(20), @nLineNumber) + char(13) + char(13)

		select @cMessage = @cMessage + '(' + convert(varchar(20), a.lineNumber) + ') ' + fileLine + char(13)
			from #fileData a
			where a.lineNumber >= @nLineNumber - 2
					and a.lineNumber <= @nLineNumber + 2
			order by a.lineNumber

		print @cSubject
		print @cMessage

		insert into notificationLog_stage (serverName, subject, message, severity) values (
			@cServerName, @cSubject, @cMessage, 2)

	end

	if exists (select top 1 [name] from tempdb..sysobjects where [name] = '##filemonitor')
		drop table ##fileMonitor

	drop table #results
	drop table #fileData
	drop table #linesFound
end



GO
