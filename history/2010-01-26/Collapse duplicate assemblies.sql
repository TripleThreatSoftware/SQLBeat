select * from assemblies where ukey_website = 12 and imageURL like '%9331%'

select imageURL, thumbnailURL, assemblyName, min(ukey) as ukey_assembly
	into #collapseAssemblies
	from assemblies (nolock)
	where ukey_website = 12
	group by imageURL, thumbnailURL, assemblyName
	having count(externalID) > 1

select a.ukey as oldUkey, b.ukey_assembly as newUkey
	into #deleteAssemblies
	from assemblies a (nolock)
	join #collapseAssemblies b on a.imageURL = b.imageURL
		and a.thumbnailURL = b.thumbnailURL
		and a.assemblyName= b.assemblyName
		and a.ukey <> b.ukey_assembly
	where a.ukey_website = 12


update assemblyProducts with (rowlock)
	set ukey_assembly = b.newUkey
	from assemblyProducts a
	join #deleteAssemblies b on a.ukey_assembly = b.oldUkey
	where a.ukey_website = 12

update assemblyImages with (rowlock)
	set ukey_assembly = b.newUkey
	from assemblyImages a
	join #deleteAssemblies b on a.ukey_assembly = b.oldUkey
	where a.ukey_website = 12

delete assemblies with (rowlock)
	from assemblies a
	join #deleteAssemblies b on a.ukey = b.oldUkey
	where a.ukey_website = 12
