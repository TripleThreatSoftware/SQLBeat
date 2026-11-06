/****** Object:  StoredProcedure [dbo].[pr_updateState]    Script Date: 11/6/2026 9:52:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from stateLog
-- select * from dm_stateKeys

CREATE procedure [dbo].[pr_updateState] (@cKeyName varchar(500), @cState varchar(200), @dYMD dateTime = '', @cCategory varchar(200) = 'Uncategorized', @bIsGood bit = 1)
as
begin
	declare @nUkeyKey int
	declare @cCurrentState varchar(200)
	declare @dLastEntry dateTime

	if isnull(@dYMD, '') = ''
		set @dYMD = getDate()

	if not exists (select top 1 [name] from sysobjects where [name] = 'dm_stateKeys')
	begin
		create table dm_stateKeys (ukey int identity, ymd dateTime default getDate(), keyName varchar(500), severity int default 1, category varchar(200) default 'Uncategorized')
		create clustered index ix_stateKeys_ukey_keyName on dm_stateKeys (ukey, keyName) with fillfactor = 80
	end

	--if not exists (select top 1 [name] from sysobjects where [name] = 'dm_stateValues')
	--begin
	--	create table dm_stateValues (ukey int identity, ymd dateTime default getDate(), ukey_stateKey int, state varchar(200), isGood bit default 1)
	--	create clustered index ix_stateValues_stateKey_state on dm_stateValues (ukey, ukey_stateKey, state) with fillfactor = 80
	--end

	if not exists (select top 1 [name] from sysobjects where [name] = 'stateLog')
	begin
		create table stateLog (ukey int identity, ymd dateTime default getDate(), ukey_stateKey int, currentState varchar(200))
		create clustered index ix_stateLog_ukey_stateKey_ymd_currentState on stateLog (ukey, ukey_stateKey, ymd, currentState) with fillfactor = 80
		create index ix_stateLog_stateKey_ymd_currentState_ukey on stateLog (ukey_stateKey, ymd, currentState, ukey) with fillfactor = 80
	end

	if not exists (select top 1 ukey from dm_stateKeys (nolock) where keyName = @cKeyName)
	begin
		insert into dm_stateKeys (keyName, ymd, category) values (@cKeyName, @dYMD, @cCategory)
		set @nUkeyKey = scope_identity()
	end
	else
		set @nUkeyKey = (select top 1 ukey from dm_stateKeys (nolock) where keyName = @cKeyName)

	--if not exists (select top 1 ukey from dm_stateValues (nolock) where ukey_stateKey = @nUkeyKey and state = @cState)
	--	insert into dm_stateValues (ukey_stateKey, state, isGood) values (@nUkeyKey, @cState, @bIsGood)

	select top 1
		@cCurrentState = currentState,
		@dLastEntry = ymd
		from stateLog (nolock)
		where ukey_stateKey = @nUkeyKey
		order by ymd desc

	if @cCurrentState is null
		set @cCurrentState = ''

	-- state needs to have changed, and we need to be receiving a new message
	if @cCurrentState <> @cState and (@dYMD > @dLastEntry or isnull(@dLastEntry, '') = '')
		insert into stateLog (ymd, ukey_stateKey, currentState) values (@dYMD, @nUkeyKey, @cState)

	update dm_stateKeys set lastData = getDate() where ukey = @nUkeyKey
end
GO
