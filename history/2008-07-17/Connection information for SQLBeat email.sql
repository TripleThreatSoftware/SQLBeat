8ritazim

smtp.sqlbeat.com
0
monitor@sqlbeat.com
c:\shared

select * from dm_settings

update dm_settings set settingValue = '8ritazim' where settingName = 'SMTP Password'
update dm_settings set settingValue = '' where settingName = 'SMTP Port'
update dm_settings set settingValue = 'smtp.sqlbeat.com' where settingName = 'SMTP Server'
update dm_settings set settingValue = '0' where settingName = 'SMTP Port'
update dm_settings set settingValue = 'monitor@sqlbeat.com' where settingName = 'SMTP User Name'
