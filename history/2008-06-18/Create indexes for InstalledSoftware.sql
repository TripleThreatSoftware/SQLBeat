use [installedSoftware]
go

create clustered index ix_runs_data_ukeyRun_ukeyServer on runs_data (ukey_run, ukey_server) with fillfactor = 60
create index ix_runs_data_ukeyServer_ukeyRun on runs_data (ukey_server, ukey_run) with fillfactor = 60
