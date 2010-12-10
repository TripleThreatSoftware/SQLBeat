create procedure pr_returnLocations (@nUkeyStudio int, @nUkeySession int)
as
begin
	select locationName, ukey
		from locations (nolock)
		where ukey_studio = @nUkeyStudio
			and ukey_session = @nUkeySession
		order by locationName
end
