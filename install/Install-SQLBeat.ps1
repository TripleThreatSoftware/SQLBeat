<#
.SYNOPSIS
    Installs SQLBeat onto a SQL Server instance from this repository's scripts.

.DESCRIPTION
    Run on the server that will host SQLBeat, from a copy of the SQLBeat repository.
    The script:
      1. Checks the instance (edition, SQL Agent, collation, existing SQLBeat databases)
      2. Enables xp_cmdshell, Agent XPs, Ole Automation Procedures and CLR
      3. Creates the Audit, Configuration, Notification and Weblogs databases
      4. Creates every table, function, view, procedure, trigger and assembly
      5. Writes SQLBeat's settings (SMTP, email, shared folder, partition paths)
      6. Copies the shared scripts to the shared folder (and can create the share)
      7. Creates the base SQL Agent jobs
      8. Creates a server group, whose trigger creates the per-group monitoring jobs
      9. Adds the first alert recipient and, optionally, the first monitored server

    Two install paths are planned:
      -JobAgent SqlAgent   SQL Server Standard edition or above (this script)
      -JobAgent FreeAgent  SQL Server Express with SQL Free Agent (not available yet)

.EXAMPLE
    .\Install-SQLBeat.ps1 -SqlInstance SQLBEAT01 -AlertEmail dba@example.com -SmtpServer smtp.example.com `
        -SharedFolder D:\SQLBeat\Shared -SharedFolderUnc \\SQLBEAT01\SQLBeatShared -CreateShare `
        -FirstServer SQLPROD01 -FirstServerType 'SQL Server'

.NOTES
    SQLBeat is a product of TTS LLC. https://www.sqlbeat.com
    Free for non-commercial use; commercial use needs a license. See LICENSE.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # SQL Server instance that will host SQLBeat.
    [string]$SqlInstance = 'localhost',
    # SQL login to install with. Omit to use Windows authentication.
    [pscredential]$SqlCredential,

    [ValidateSet('SqlAgent', 'FreeAgent')]
    [string]$JobAgent = 'SqlAgent',

    # Where to put the database files. Omit to use the instance defaults.
    [string]$DataPath,
    [string]$LogPath,
    # Where SQLBeat creates its monthly partition databases. Defaults to DataPath / LogPath.
    [string]$PartitionDataPath,
    [string]$PartitionLogPath,

    # Local folder on the SQLBeat server for the shared scripts.
    [Parameter(Mandatory)][string]$SharedFolder,
    # How monitored servers reach that folder. Defaults to \\<this computer>\SQLBeatShared.
    [string]$SharedFolderUnc,
    # Create an SMB share for SharedFolder (needs admin rights on this computer).
    [switch]$CreateShare,

    # Alerts
    [Parameter(Mandatory)][string]$AlertEmail,
    [string]$FromEmail,
    [Parameter(Mandatory)][string]$SmtpServer,
    [int]$SmtpPort = 25,
    [pscredential]$SmtpCredential,
    [switch]$SmtpSsl,

    # Login that owns SQLBeat's jobs.
    [string]$JobOwner = 'sa',
    # First server group. Its trigger creates the per-group monitoring jobs.
    [string]$ServerGroup = 'Production',

    # Optional first server to monitor.
    [string]$FirstServer,
    [ValidateSet('SQL Server', 'Server', 'IIS Web Server')]
    [string]$FirstServerType = 'SQL Server',
    [pscredential]$FirstServerSqlCredential,
    [pscredential]$FirstServerWmiCredential,

    # Install even if SQLBeat databases already exist (objects are dropped and re-created).
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Databases = 'Notification', 'Audit', 'Configuration', 'Weblogs'
$ObjectOrder = 'functions', 'views', 'procedures', 'triggers'

function Write-Step($Text) { Write-Host "`n== $Text" -ForegroundColor Cyan }

# ---------------------------------------------------------------- SQL helpers
$script:Connections = @{}

function Get-Connection([string]$Database = 'master') {
    if (-not $script:Connections[$Database]) {
        $b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
        $b['Data Source'] = $SqlInstance
        $b['Initial Catalog'] = $Database
        $b['Application Name'] = 'SQLBeat installer'
        if ($SqlCredential) {
            $b['User ID'] = $SqlCredential.UserName
            $b['Password'] = $SqlCredential.GetNetworkCredential().Password
        } else {
            $b['Integrated Security'] = $true
        }
        $c = New-Object System.Data.SqlClient.SqlConnection $b.ConnectionString
        $c.Open()
        $script:Connections[$Database] = $c
    }
    $script:Connections[$Database]
}

function Invoke-Sql([string]$Sql, [string]$Database = 'master', [hashtable]$Parameters = @{}, [switch]$Scalar) {
    $cmd = (Get-Connection $Database).CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = 0
    foreach ($k in $Parameters.Keys) { [void]$cmd.Parameters.AddWithValue("@$k", $(if ($null -eq $Parameters[$k]) { [DBNull]::Value } else { $Parameters[$k] })) }
    if ($Scalar) { return $cmd.ExecuteScalar() }
    $t = New-Object System.Data.DataTable
    $r = $cmd.ExecuteReader()
    $t.Load($r)
    $r.Close()
    , $t
}

# Split a script on GO lines. Each batch remembers the SET ANSI_NULLS / QUOTED_IDENTIFIER
# in force before it, because those settings are stored with the object when it is created.
function Get-Batches([string]$Path) {
    $text = [IO.File]::ReadAllText($Path) -replace "`r`n", "`n"
    $state = @{ ANSI_NULLS = 'ON'; QUOTED_IDENTIFIER = 'ON' }
    foreach ($b in [regex]::Split($text, '(?m)^[ \t]*GO[ \t]*(?:--[^\n]*)?$')) {
        if (-not $b.Trim()) { continue }
        $code = ($b -replace '(?s)/\*.*?\*/', '' -replace '--[^\n]*', '').Trim()
        if ($code -match '^(?i)SET\s+(ANSI_NULLS|QUOTED_IDENTIFIER)\s+(ON|OFF)\s*;?$') {
            $state[$Matches[1].ToUpper()] = $Matches[2].ToUpper(); continue
        }
        if ($code -match '^(?i)SET\s+ANSI_PADDING') { continue }
        if (-not $code) { continue }
        [pscustomobject]@{ File = $Path; Sql = $b; AnsiNulls = $state.ANSI_NULLS; QuotedId = $state.QUOTED_IDENTIFIER }
    }
}

function Invoke-Batch($Batch, [string]$Database) {
    $c = Get-Connection $Database
    $cmd = $c.CreateCommand()
    $cmd.CommandTimeout = 0
    $cmd.CommandText = "SET ANSI_NULLS $($Batch.AnsiNulls); SET QUOTED_IDENTIFIER $($Batch.QuotedId);"
    [void]$cmd.ExecuteNonQuery()
    $cmd.CommandText = $Batch.Sql
    [void]$cmd.ExecuteNonQuery()
}

function Set-Setting([string]$Name, $Value) {
    Invoke-Sql -Database Notification -Parameters @{ n = $Name; v = "$Value" } -Sql @'
if exists (select 1 from dm_settings where settingName = @n)
    update dm_settings set settingValue = @v where settingName = @n
else
    insert into dm_settings (settingName, settingValue) values (@n, @v)
'@ | Out-Null
}

# ---------------------------------------------------------------- 1. checks
Write-Step "Checking $SqlInstance"

if ($JobAgent -eq 'FreeAgent') {
    throw "The SQL Server Express path (SQL Free Agent) is not available yet. See https://www.sqlfreeagent.com for news."
}

$info = Invoke-Sql @'
select cast(serverproperty('ProductMajorVersion') as int) as major,
       cast(serverproperty('EngineEdition') as int) as engine,
       cast(serverproperty('Edition') as nvarchar(200)) as edition,
       cast(serverproperty('Collation') as nvarchar(200)) as collation,
       cast(serverproperty('MachineName') as nvarchar(200)) as machine,
       @@servername as servername
'@
$info = $info.Rows[0]
Write-Host "SQL Server $($info.major) $($info.edition) on $($info.machine), collation $($info.collation)"

if ($info.engine -eq 4) {
    throw "This is SQL Server Express, which has no SQL Agent. Express will be supported through SQL Free Agent (-JobAgent FreeAgent), which is not available yet."
}
if ($info.major -lt 11) { Write-Warning "SQL Server versions before 2012 have not been tested with this installer." }

$agent = Invoke-Sql "select status_desc from sys.dm_server_services where servicename like 'SQL Server Agent%'"
if ($agent.Rows.Count -and $agent.Rows[0].status_desc -ne 'Running') {
    throw "SQL Server Agent is not running on $SqlInstance. Start it and set it to start automatically, then run the installer again."
}
if ($info.collation -notmatch '_CI_') { Write-Warning "SQLBeat expects a case-insensitive server collation; this instance uses $($info.collation)." }

$existing = (Invoke-Sql "select name from sys.databases where name in ('Notification','Audit','Configuration','Weblogs')").Rows | ForEach-Object name
if ($existing -and -not $Force) {
    throw "SQLBeat databases already exist on ${SqlInstance}: $($existing -join ', '). Use -Force to drop and re-create their objects."
}

if (-not $FromEmail) { $FromEmail = $AlertEmail }
if (-not $SharedFolderUnc) { $SharedFolderUnc = "\\$($env:COMPUTERNAME)\SQLBeatShared" }
if (-not $PartitionDataPath) { $PartitionDataPath = $(if ($DataPath) { $DataPath } else { (Invoke-Sql "select cast(serverproperty('InstanceDefaultDataPath') as nvarchar(400))" -Scalar) }) }
if (-not $PartitionLogPath) { $PartitionLogPath = $(if ($LogPath) { $LogPath } else { (Invoke-Sql "select cast(serverproperty('InstanceDefaultLogPath') as nvarchar(400))" -Scalar) }) }

# ---------------------------------------------------------------- 2. server options
Write-Step 'Setting server options'
if ($PSCmdlet.ShouldProcess($SqlInstance, 'Enable xp_cmdshell, Agent XPs, Ole Automation Procedures, CLR')) {
    Invoke-Sql @'
exec sp_configure 'show advanced options', 1; reconfigure;
exec sp_configure 'xp_cmdshell', 1;
exec sp_configure 'Agent XPs', 1;
exec sp_configure 'Ole Automation Procedures', 1;
exec sp_configure 'clr enabled', 1;
reconfigure;
'@ | Out-Null
}

# ---------------------------------------------------------------- 3. databases
Write-Step 'Creating databases'
foreach ($db in $Databases) {
    if ($existing -contains $db) { Write-Host "$db exists, keeping it"; continue }
    $files = ''
    if ($DataPath -and $LogPath) {
        $files = " ON PRIMARY (NAME = N'$db', FILENAME = N'$(Join-Path $DataPath "$db.mdf")', SIZE = 256MB, FILEGROWTH = 256MB)" +
                 " LOG ON (NAME = N'${db}_log', FILENAME = N'$(Join-Path $LogPath "$db.ldf")', SIZE = 64MB, FILEGROWTH = 128MB)"
    }
    if ($PSCmdlet.ShouldProcess($db, 'Create database')) {
        Invoke-Sql "CREATE DATABASE [$db]$files" | Out-Null
        # Database options from the scripted database, minus file layout and features this version may lack
        foreach ($b in Get-Batches (Join-Path $RepoRoot "databases\$db\database.sql")) {
            if ($b.Sql -notmatch '(?i)^\s*ALTER DATABASE') { continue }
            try { Invoke-Batch $b master } catch { Write-Verbose "Skipped option: $($b.Sql.Trim()) ($($_.Exception.Message))" }
        }
        Invoke-Sql "ALTER DATABASE [$db] SET RECOVERY SIMPLE" | Out-Null
    }
}

# ---------------------------------------------------------------- 4. objects
Write-Step 'Creating objects'
if ($Force -and $existing) {
    foreach ($db in $existing) {
        Write-Host "Dropping existing SQLBeat objects in $db"
        Invoke-Sql -Database $db @'
declare @s nvarchar(max) = N''
select @s += N'drop trigger ' + quotename(schema_name(o.schema_id)) + '.' + quotename(o.name) + ';' from sys.objects o where o.type = 'TR' and o.parent_object_id <> 0
select @s += N'alter table ' + quotename(schema_name(t.schema_id)) + '.' + quotename(t.name) + ' drop constraint ' + quotename(f.name) + ';' from sys.foreign_keys f join sys.tables t on t.object_id = f.parent_object_id
select @s += N'drop ' + case type when 'P' then 'procedure' when 'V' then 'view' when 'U' then 'table' else 'function' end + ' ' + quotename(schema_name(schema_id)) + '.' + quotename(name) + ';'
    from sys.objects where type in ('P','V','FN','IF','TF','FS','FT','U') and is_ms_shipped = 0
select @s += N'drop assembly ' + quotename(name) + ';' from sys.assemblies where is_user_defined = 1
exec (@s)
'@ | Out-Null
    }
}

# CLR assembly (Weblogs): trust it explicitly on SQL Server 2017+ where 'clr strict security' is on
foreach ($file in Get-ChildItem (Join-Path $RepoRoot 'databases\*\assemblies\*.sql')) {
    $db = $file.Directory.Parent.Name
    $sql = [IO.File]::ReadAllText($file.FullName)
    if ($info.major -ge 14 -and $sql -match 'FROM\s+0x([0-9A-Fa-f]+)') {
        $hex = $Matches[1]
        $bytes = [byte[]]::new($hex.Length / 2)
        for ($i = 0; $i -lt $bytes.Length; $i++) { $bytes[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16) }
        $hash = [Security.Cryptography.SHA512]::Create().ComputeHash($bytes)
        $name = if ($sql -match 'CREATE ASSEMBLY \[([^\]]+)\]') { $Matches[1] } else { $file.BaseName }
        if ($PSCmdlet.ShouldProcess($name, 'Trust CLR assembly')) {
            Invoke-Sql -Parameters @{ h = $hash; d = "SQLBeat $name" } @'
if not exists (select 1 from sys.trusted_assemblies where hash = @h)
    exec sys.sp_add_trusted_assembly @hash = @h, @description = @d
'@ | Out-Null
        }
    }
    if ($PSCmdlet.ShouldProcess("$db $($file.Name)", 'Create assembly')) {
        foreach ($b in Get-Batches $file.FullName) { Invoke-Batch $b $db }
    }
}

# Tables first in every database, then programmable objects. Objects can depend on each other
# (and on other SQLBeat databases), so failed batches are retried until nothing more succeeds.
$queue = New-Object System.Collections.Generic.List[object]
foreach ($kind in @('types', 'tables') + $ObjectOrder) {
    foreach ($db in $Databases) {
        $dir = Join-Path $RepoRoot "databases\$db\$kind"
        if (-not (Test-Path $dir)) { continue }
        foreach ($f in Get-ChildItem $dir -Filter *.sql | Sort-Object Name) {
            foreach ($b in Get-Batches $f.FullName) { $queue.Add([pscustomobject]@{ Db = $db; Batch = $b; Error = $null }) }
        }
    }
}
Write-Host "$($queue.Count) batches to run"
if ($PSCmdlet.ShouldProcess($SqlInstance, "Create SQLBeat objects")) {
    $pass = 0
    while ($queue.Count) {
        $pass++
        $failed = New-Object System.Collections.Generic.List[object]
        foreach ($item in $queue) {
            try { Invoke-Batch $item.Batch $item.Db }
            catch { $item.Error = $_.Exception.InnerException.Message; if (-not $item.Error) { $item.Error = $_.Exception.Message }; $failed.Add($item) }
        }
        Write-Host "Pass ${pass}: $($queue.Count - $failed.Count) succeeded, $($failed.Count) to retry"
        if ($failed.Count -eq $queue.Count) { break }
        $queue = $failed
    }
    if ($queue.Count -and $failed.Count) {
        Write-Warning "$($failed.Count) batches could not be created:"
        foreach ($item in $failed) { Write-Warning "  $($item.Db): $(Split-Path -Leaf $item.Batch.File): $($item.Error)" }
    }
}

# ---------------------------------------------------------------- 5. settings
Write-Step 'Writing settings'
if ($PSCmdlet.ShouldProcess('Notification.dbo.dm_settings', 'Write settings')) {
    $machine = ($info.servername -split '\\')[0]
    $settings = [ordered]@{
        'Job Owner'                             = $JobOwner
        'Current machine name'                  = $machine
        'Default Email From'                    = $FromEmail
        'Default Email To'                      = $AlertEmail
        'Shared Folder'                         = ($SharedFolderUnc.TrimEnd('\') + '\')
        'Shared Folder Local Path'              = ($SharedFolder.TrimEnd('\') + '\')
        'SQLPing Location'                      = ($SharedFolder.TrimEnd('\') + '\')
        'Partition Data Path'                   = ($PartitionDataPath.TrimEnd('\') + '\')
        'Partition Log Path'                    = ($PartitionLogPath.TrimEnd('\') + '\')
        'Long running query threshold'          = 60
        'Page Life Expectancy Window Minutes'   = 10
        'Page Life Expectancy Low Threshold'    = 300
        'Watch SQLBeat Running Processes'       = 1
        'Watch SQLBeat CPU and Disk Queues'     = 1
    }
    foreach ($k in $settings.Keys) { Set-Setting $k $settings[$k] }

    $smtpUser = if ($SmtpCredential) { $SmtpCredential.UserName } else { '' }
    $smtpPass = if ($SmtpCredential) { $SmtpCredential.GetNetworkCredential().Password } else { '' }
    Invoke-Sql -Database Notification -Parameters @{ s = $SmtpServer; p = $SmtpPort; u = $smtpUser; w = $smtpPass; ssl = [bool]$SmtpSsl } `
        'exec pr_setSMTPConfiguration @s, @p, @u, @w, @ssl' | Out-Null
}

# ---------------------------------------------------------------- 6. shared folder
Write-Step "Copying shared scripts to $SharedFolder"
if ($PSCmdlet.ShouldProcess($SharedFolder, 'Copy shared scripts')) {
    New-Item -ItemType Directory -Force -Path $SharedFolder | Out-Null
    Copy-Item (Join-Path $RepoRoot 'shared\*') $SharedFolder -Recurse -Force
    if ($CreateShare) {
        $shareName = ($SharedFolderUnc.TrimEnd('\') -split '\\')[-1]
        if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
            New-SmbShare -Name $shareName -Path $SharedFolder -ReadAccess 'Everyone' -Description 'SQLBeat shared scripts' | Out-Null
            Write-Host "Created share $SharedFolderUnc (read access for Everyone; narrow this to the monitored servers' service accounts)"
        }
    }
}

# ---------------------------------------------------------------- 7. jobs
Write-Step 'Creating base jobs'
foreach ($f in Get-ChildItem (Join-Path $RepoRoot 'jobs') -Filter *.sql | Sort-Object Name) {
    if (-not $PSCmdlet.ShouldProcess($f.BaseName, 'Create job')) { continue }
    $name = $f.BaseName
    Invoke-Sql -Database msdb -Parameters @{ n = $name } "if exists (select 1 from msdb.dbo.sysjobs where name = @n) exec msdb.dbo.sp_delete_job @job_name = @n" | Out-Null
    foreach ($b in Get-Batches $f.FullName) {
        $b.Sql = $b.Sql -replace "@owner_login_name=N'sa'", "@owner_login_name=N'$($JobOwner -replace "'", "''")'"
        if ($b.Sql -match '(?i)^\s*USE\s+\[?msdb\]?\s*$') { continue }
        Invoke-Batch $b msdb
    }
    Write-Host "  $name"
}

# ---------------------------------------------------------------- 8. server group
Write-Step "Creating server group '$ServerGroup'"
$groupKey = $null
if ($PSCmdlet.ShouldProcess($ServerGroup, 'Create server group and its jobs')) {
    Invoke-Sql -Database Notification -Parameters @{ g = $ServerGroup } 'exec pr_addNewServerGroup @g, 1' | Out-Null
    $groupKey = Invoke-Sql -Database Notification -Parameters @{ g = $ServerGroup } 'select ukey from dm_serverGroups where groupName = @g' -Scalar
}

# ---------------------------------------------------------------- 9. recipient and first server
Write-Step 'Adding the first alert recipient'
if ($PSCmdlet.ShouldProcess($AlertEmail, 'Add alert recipient and rule')) {
    Invoke-Sql -Database Notification -Parameters @{ e = $AlertEmail } @'
if not exists (select 1 from userEmails where emailAddress = @e)
    insert into userEmails (userName, emailAddress) values ('DBA', @e)
declare @k int = (select top 1 ukey from userEmails where emailAddress = @e)
if not exists (select 1 from messageRules where ukey_userEmail = @k)
    insert into messageRules (userName, ukey_userEmail, sendMessage) values ('DBA', @k, 1)
'@ | Out-Null
}

if ($FirstServer -and $PSCmdlet.ShouldProcess($FirstServer, "Monitor as $FirstServerType")) {
    Write-Step "Adding $FirstServer as a $FirstServerType"
    $p = @{
        s = $FirstServer; t = $FirstServerType; g = [int]$groupKey; w = $true
        su = $(if ($FirstServerSqlCredential) { $FirstServerSqlCredential.UserName } else { '' })
        sp = $(if ($FirstServerSqlCredential) { $FirstServerSqlCredential.GetNetworkCredential().Password } else { '' })
        wu = $(if ($FirstServerWmiCredential) { $FirstServerWmiCredential.UserName } else { '' })
        wp = $(if ($FirstServerWmiCredential) { $FirstServerWmiCredential.GetNetworkCredential().Password } else { '' })
    }
    Invoke-Sql -Database Notification -Parameters $p 'exec pr_configureForType @s, @t, @g, @w, @su, @sp, @wu, @wp' | Out-Null
}

foreach ($c in $script:Connections.Values) { $c.Close() }

Write-Step 'Done'
Write-Host @"
SQLBeat is installed on $SqlInstance.

Next:
  - Check that the monitored servers' SQL Server service accounts can read $SharedFolderUnc
  - Add servers with:  exec Notification.dbo.pr_configureForType '<server>', 'SQL Server' | 'Server' | 'IIS Web Server', <group ukey>
  - Watch Notification.dbo.notificationLog for the first alerts, and confirm email arrives at $AlertEmail

Questions: https://github.com/TripleThreatSoftware/SQLBeat/discussions
Paid installation, configuration and support: https://www.sqlbeat.com/pricing
"@
