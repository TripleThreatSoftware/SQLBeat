# SQLBeat

Agentless, source-available monitoring and SIEM for Microsoft SQL Server, built entirely
in SQL Server: tables, stored procedures, functions, triggers and SQL Agent jobs.
A product of TTS LLC. https://www.sqlbeat.com

> **Status:** private while the code is prepared for release. The installer is new and not yet tested end to end.

## Layout

| Path | What it holds |
|---|---|
| `databases/Audit/` | Change management and auditing: object changes, rights, AD users and computers, files |
| `databases/Configuration/` | Windows/WMI monitoring: counters, processes, IIS and config file snapshots |
| `databases/Notification/` | The core: server inventory, SQL monitoring, alert rules engine, message staging, settings |
| `databases/Weblogs/` | IIS/Apache weblog import, web farm and URL monitoring |
| `jobs/` | The base SQL Agent jobs. Further jobs are created automatically (see below). |
| `shared/` | Scripts SQLBeat runs against monitored servers (`.sql` via OSQL/sqlcmd, `.ps1` for WMI, event logs, AD) |

Each database folder has `database.sql` plus one file per object under `tables/`,
`procedures/`, `functions/`, `views/`, `triggers/` and `assemblies/`.
Indexes, defaults and constraints live in their table's file. Documented tables carry a
description header and per-column notes; documented procedures carry a description header.

Configuration, Notification and Weblogs create monthly child databases automatically
(for example `Weblogs202610` for October 2026). Those are not scripted here.

## History

The history goes back to June 2008 and was rebuilt from the daily change file:
one commit per day, dated to that day. Each object's file shows its full history
(`git log --follow databases/Notification/procedures/dbo.pr_examineServer.sql`).
One-off scripts from those days (data fixes, tests, setup) are under `history/` in the
commits where they were run, and are removed in the latest snapshot commit.
That commit is a full script-out of the running system on 2026-11-06,
which includes the 2025 object renames.

Throughout the history, passwords are replaced with `REDACTED`, and customer names,
customer server names, domains and people are replaced with generic names
(`AppDb`, `sqldb39`, `example.com`). Customer application code that had been kept
alongside SQLBeat is left out.

## Installing

- **SQL Server Standard edition or above:** run `install/Install-SQLBeat.ps1` from an elevated PowerShell 7 prompt.
  Jobs run on the built-in SQL Server Agent. `Get-Help .\install\Install-SQLBeat.ps1 -Full` lists every option;
  add `-WhatIf` to see what it would do. Full guide: https://www.sqlbeat.com/install.html
- **SQL Server Express:** jobs will run on [SQL Free Agent](https://www.sqlfreeagent.com). This path is not available yet.

```powershell
.\install\Install-SQLBeat.ps1 -SqlInstance SQLBEAT01 -SharedFolder D:\SQLBeat\Shared `
    -SharedFolderUnc \\SQLBEAT01\SQLBeatShared -CreateShare `
    -AlertEmail dba@example.com -SmtpServer smtp.example.com `
    -FirstServer SQLPROD01 -FirstServerType 'SQL Server'
```

### What the installer does (from the legacy installer's steps)

The old Inno Setup installer also installed SQL Server Express and an ASP.NET control panel;
neither is part of SQLBeat any more. The rest of its steps still apply:

1. **SQL Server instance** dedicated to SQLBeat, SQL authentication enabled, TCP and named pipes on,
   default collation.
2. **Prerequisites** on the SQLBeat server: PowerShell 7, Visual C++ runtime, Microsoft OLE DB Driver for SQL Server.
3. **Server options:** enable `xp_cmdshell`, `Agent XPs` and `Ole Automation Procedures`.
4. **Create the databases** Audit, Configuration, Notification and Weblogs and their objects.
5. **Settings** in `Notification..dm_settings`: job owner, machine name, SMTP server/port/credentials/SSL,
   default from/to email, shared folder path, partition data and log paths, thresholds.
6. **Monitoring credentials:** SQLBeat reaches monitored servers as its SQL Server service account,
   or with per-server SQL and WMI credentials stored in `dm_servers`.
7. **Shared folder** on the SQLBeat server, holding `shared/`, readable by the service accounts of
   the monitored servers; record its UNC and local paths in `dm_settings`.
8. **Base jobs** from `jobs/`.
9. **Server group:** create at least one row in `Notification..dm_serverGroups`. Its trigger
   (`trg_serverGroups`) creates the per-group monitoring jobs
   (`update dm_serverGroups set isProduction = isProduction` re-runs it).
10. **First alert recipient and rule:** a row in `userEmails` and one in `messageRules`.
11. **First monitored server:** add it to `dm_servers` with its credentials and group, then confirm data
    is arriving and alert email is delivered.

## License

Free for non-commercial use under the [PolyForm Noncommercial License 1.0.0](LICENSE.md).
Commercial use needs a license from TTS LLC: see [COMMERCIAL.md](COMMERCIAL.md).

## Help

Questions go in [Discussions](https://github.com/TripleThreatSoftware/SQLBeat/discussions); see [SUPPORT.md](SUPPORT.md).
