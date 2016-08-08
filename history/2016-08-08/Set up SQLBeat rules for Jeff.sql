select top 1000 * from notificationLog order by ymd desc
select top 1000 * from eventLog where logtype = 'system' order by ukey desc

select * from dm_serverGroups
select * from messageRules where username = 'jeff pratt'
select * from userEmails
insert into userEmails (userName, emailAddress) values ('Jeff Pratt', 'jeff-alerts@triplethreatsoftware.com')

drive out of space
high cpu load
queues
memory
hardware failure
NIC connectivity
server reboots

select *
	from notificationLog
	where isDriveSpace = 1
		or isConnectivity = 1
		or (isEventLog = 1 and subject not like '%httpexception%' and severity in (1,2) and message not like '%aspx%' and subject not like '%sqlexception%')
		or subject like '%cpu%'
		or subject like '%disk%'

delete from messageRules where username = 'Jeff Pratt'


insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, isDriveSpace) values (6, 1, 'Jeff Pratt', 1, 0, 1)
insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, isConnectivity) values (6, 1, 'Jeff Pratt', 1, 0, 1)
insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, isEventLog, severity, messageLike) values (6, 1, 'Jeff Pratt', 1, 0, 1, 1, 'type: system')
insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, isEventLog, severity, messageLike) values (6, 1, 'Jeff Pratt', 1, 0, 1, 2, 'type: system')
insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, isEventLog, severity, messageLike) values (6, 1, 'Jeff Pratt', 1, 0, 1, 3, 'type: system')

insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, subjectLike, allMessages) values (6, 1, 'Jeff Pratt', 1, 0, 'CPU', 1)
insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, subjectLike, allMessages) values (6, 1, 'Jeff Pratt', 1, 0, 'disk', 1)
insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, subjectLike, allMessages) values (6, 1, 'Jeff Pratt', 1, 0, 'memory', 1)
insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, subjectLike, allMessages) values (6, 1, 'Jeff Pratt', 1, 0, 'hardware', 1)
insert into messageRules (ukey_useremail, ukey_group, userName, sendMessage, doNotSendMessage, subjectLike, allMessages) values (6, 1, 'Jeff Pratt', 1, 0, 'requests waiting', 1)

insert into messageRules (userName, sendMessage, doNotSendMessage, subjectLike) values ('Jeff Pratt', 0, 1, 'httpexception')
insert into messageRules (userName, sendMessage, doNotSendMessage, subjectLike) values ('Jeff Pratt', 0, 1, 'sqlexception')
insert into messageRules (userName, sendMessage, doNotSendMessage, messageLike) values ('Jeff Pratt', 0, 1, 'aspx')
insert into messageRules (userName, sendMessage, doNotSendMessage, messageLike) values ('Jeff Pratt', 0, 1, 'event code: 3012')

exec pr_sendAlerts 'jeff pratt', 1
