create clustered index ix_conversations_ukey on conversations (ukey) with fillfactor = 80
go
create index ix_conversations_website_ukey on conversations (ukey_website, ukey) with fillfactor = 80
go
