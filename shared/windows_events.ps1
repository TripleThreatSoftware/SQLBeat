param($cTimestamp = '2024-03-13 15:45:00.000')

#Get Functions
if ($psISE){
    (Get-ChildItem (Join-Path (Split-Path $psISE.CurrentFile.FullPath) Functions) -Filter *.ps1) | ForEach-Object {. $_.FullName}
}elseif($env:TERM_PROGRAM -eq 'vscode'){
    (Get-ChildItem (Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') Functions) -Filter *.ps1) | ForEach-Object {. $_.FullName}
}else{
    (Get-ChildItem (Join-Path $PSScriptRoot Functions) -Filter *.ps1) | ForEach-Object {. $_.FullName}
}

[Byte[]] $key = (1..16)
$CorpUserId = "CORP\monitoringservice"
$AdUserId = "ad.example.com\SA_Monitoring"
$EncryptedPassword = 'REDACTED'
$CorpCredential = Test-Credential $(New-Object System.Management.Automation.PSCredential -ArgumentList ($CorpUserId, ($EncryptedPassword | ConvertTo-SecureString -Key $key)))
$AdCredential = Test-Credential $(New-Object System.Management.Automation.PSCredential -ArgumentList ($AdUserId, ($EncryptedPassword | ConvertTo-SecureString -Key $key)))
 

$SB = {  
    param([datetime]$cTimestamp)

    $filterxml = @"
    <QueryList>
      <Query Id="0" Path="Application">
        <Select Path="Application">
			    *[System[(Level=1  or Level=2 or Level=3)]]
			    and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
		    </Select>
        <Select Path="System">
			    *[System[(Level=1 or Level=2 or Level=3 or Level=0)
			    or Provider[@Name='Kernel-General']
			    or Provider[@Name='EventLog']
			    or Provider[@Name='USER32']
			    or Provider[@Name='Microsoft-Windows-Kernel-General']
			    or Provider[@Name='Microsoft-Windows-WAS']]]
			    and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
	    </Select>
        <Suppress Path="System">
			    *[System[(EventID='36871')
			    or (EventID='36887')
			    or (EventID='36874')
			    or (EventID='36888')
			    or (EventID='4663')
			    or (EventID='4656')
			    or (EventID='4658')
			    or (EventID='4690')
			    or (EventID='4624')]]			
	    </Suppress>
      </Query>
    </QueryList>
"@
    get-winevent -FilterXml $filterxml | select 'RecordId',@{N='Log Type';E={$_.LogName}},@{N='Level';E={$_.LevelDisplayName}},@{N='Date and Time';E={$_.TimeCreated}},
        @{N='Source';E={$_.ProviderName}},@{N='Event ID';E={$_.ID}},'Message'

}# End of Script Block

#splatting invoke arguments
$InvokeArgs = @{
    ComputerName = $(Get-LDAPServers | Where {$_ -match 'corp.example.com'})
    ScriptBlock = $SB
    Credential = $CorpCredential
    ArgumentList = $cTimestamp
    }

Invoke-Command @InvokeArgs -AsJob  | Out-Null

$InvokeArgs = @{
    ComputerName = $(Get-LDAPServers | Where {$_ -match 'ad.example.com'})
    ScriptBlock = $SB
    Credential = $AdCredential
    ArgumentList = $cTimestamp
    }

Invoke-Command @InvokeArgs -AsJob  | Out-Null

$Data = Start-AsJobHandler

# Database variables
$sqlserver = "sqlbeat01.corp.example.com"
$database = "Notification"
$table = "RyansEventLog"

$Select =  @{N='computerName';E={$_.PSComputerName}},'RecordId', @{N='LogType';E={$_.'Log Type'}},'Level', @{N='DateAndTime';E={$_.'Date and Time'}},'Source', @{N='EventID';E={$_.'Event ID'}},'Message' 

Set-SqlData -data $($Data.RespondingSystems | select $Select) -server $sqlserver -database $database -table $table


#write errors to SQL error table
# Database variables
$sqlserver = "sqlbeat01.corp.example.com"
$database = "Notification"
$table = "readWindowsEvents_error"

$Select =  @{N='DateAndTime';E={$_.'Date and Time'}},@{N='computerName';E={$_."Computer Name"}},@{N='error';E={$_.'Error'}}

Set-SqlData -data $($Data.NOT_RespondingSystems | select $Select) -server $sqlserver -database $database -table $table