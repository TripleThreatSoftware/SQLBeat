select 'select ''' + a.name + ''', * from [' + a.name + '] where [' + b.name + '] = 61702'
	from sysobjects a
	join syscolumns b on a.id = b.id
	where b.name like '%fkt141%'

select * from where fk190_text = 61702
