select * from messageRules
select * from dm_Settings
select * from dm_serverGroups
select * from userEmails

update userEmails set emailAddress = REPLACE(emailAddress, '-list', '')
update notificationsSent set emailAddress = REPLACE(emailAddress, '-list', '')
select * from notificationsSent

delete from notificationsSent where dateSent >= '2013-04-25 12:01:32.060'

insert into userEmails (userName, emailAddress) values ('Critical', 'alerts-list@triplethreatsoftware.com')
insert into userEmails (userName, emailAddress) values ('NonCritical', 'alerts-list-noncritical@triplethreatsoftware.com')

update dm_settings set settingValue = 'monitor@sqlbeat.com' where ukey = 12
update dm_settings set settingValue = 'alerts@triplethreatsoftware.com' where ukey = 13

insert into messageRules (userName, sendMessage, doNotSendMessage, businessHours, offHours, ukey_userEmail, ukey_group, severity) values ('Critical', 1, 0, 1, 1, 1, 1, 1)
insert into messageRules (userName, sendMessage, doNotSendMessage, businessHours, offHours, ukey_userEmail) values ('NonCritical', 1, 0, 1, 1, 2)

insert into messageRules (userName, sendMessage, doNotSendMessage, businessHours, offHours, ukey_userEmail, serverEquals) values ('NonCritical', 1, 0, 1, 1, 2, 'web09')

insert into messageRules (sendMessage, doNotSendMessage, subjectLike) values (0, 1, 'fulfillment')
insert into messageRules (sendMessage, doNotSendMessage, subjectLike) values (0, 1, 'jointuser')
insert into messageRules (sendMessage, doNotSendMessage, messageLike) values (0, 1, 'fatal alert%1203')

update messageRules set severity = 2 where ukey = 4



insert into messageRules (sendMessage, doNotSendMessage, messageLike) values (0, 1, 'a potentially dangerous')
insert into messageRules (sendMessage, doNotSendMessage, messageLike) values (0, 1, 'error converting data type nvarchar to int')
insert into messageRules (sendMessage, doNotSendMessage, messageLike) values (0, 1, 'conversion from string')
insert into messageRules (sendMessage, doNotSendMessage, messageLike) values (0, 1, 'not recognized as a valid datetime')
insert into messageRules (sendMessage, doNotSendMessage, messageLike) values (0, 1, 'fatal alert%1203')
