create procedure pr_addJob (@cJobName varchar(200), @nUkeyJob int OUT)
as
begin
	declare @cMessage varchar(8000)

	if exists (select top 1 ukey from jobs (nolock) where jobName = @cJobName)
	begin
		print 'Job [' + @cJobName + '] already exists!'
		return
	end

	if isnull(@cJobName, '') = ''
	begin
		print 'Job name cannot be empty'
		return
	end

	insert into jobs (jobName, isEnabled) values (@cJobName, 1)

	set @nUkeyJob = scope_identity()

end
GO
