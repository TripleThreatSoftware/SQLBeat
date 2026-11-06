param($cTimestamp = '2024-03-12 20:30:00.000')

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
    #https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4663
    #More than 21 event sources need to be split into seperate queries.
    $filterxml = @"
    <QueryList>
        <Query Id="0" Path="Security">
            <Select Path="Security">
                *[System[(Level=1  or Level=2 or Level=3 or Level=4 or Level=0 or Level=5) and (
                EventID=4618 or <!--A monitored security event pattern has occurred.-->
                EventID=4649 or <!--A replay attack was detected. May be a harmless false positive due to misconfiguration error.-->
                EventID=4765 or <!--SID History was added to an account.-->
                EventID=4766 or <!--An attempt to add SID History to an account failed.-->
                EventID=4794 or <!--An attempt was made to set the Directory Services Restore Mode.-->
                EventID=4897 or <!--Role separation enabled.-->
                EventID=4964 or <!--Special groups have been assigned to a new logon.-->
                EventID=1102 or <!--The audit log was cleared-->
                EventID=4740 or <!--A user account was locked out.-->                
                EventID=4767 or <!--A user account was unlocked.-->
                EventID=4698 or <!--A Scheduled task was created.-->
                EventID=4700 or <!--A Scheduled task was enabled.-->
                EventID=4950 or <!--A setting was changed in Windows Firewall.-->
                EventID=4954 or <!--Group Policy settings for Windows Firewall has changed.-->
                EventID=5025 or <!--The Windows Firewall service has been stopped.-->
                EventID=5136 or <!--A directory service object was modified.-->
                EventID=5137 or <!--A directory service object was created.-->
                EventID=5141 <!--A directory service object was deleted.-->
                )]]
                and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
            </Select>
        </Query>
        <Query Id="1" Path="Security">
            <Select Path="Security">
                *[System[(Level=1  or Level=2 or Level=3 or Level=4 or Level=0 or Level=5) and (
                EventID=6272 or <!--Network Policy Server granted access to a user.-->
                EventID=6273 or <!--Network Policy Server denied access to a user.-->
                EventID=6274 or <!--Network Policy Server discarded the request for a user.-->
                EventID=6275 or <!--Network Policy Server discarded the accounting request for a user.-->
                EventID=6276 or <!--Network Policy Server quarantined a user.-->
                EventID=6277 or <!--Network Policy Server granted access to a user but put it on probation because the host did not meet the defined health policy.-->
                EventID=6278 or <!--Network Policy Server granted full access to a user because the host met the defined health policy.-->
                EventID=6279 or <!--Network Policy Server locked the user account due to repeated failed authentication attempts.-->
                EventID=6280 or <!--Network Policy Server unlocked the user account.-->
                EventID=13 or <!--A RADIUS message was received from the invalid RADIUS client IP address xx.xx.xx.xx-->
                EventID=18 <!--An Access-Request message was received from RADIUS client %1 with a message authenticator attribute that isn't valid-->
                )]]
                and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
            </Select>
        </Query>
        <Query Id="2" Path="Security">
            <Select Path="System">
                *[System[(
                EventID=7045 <!-- New Service Installed -->
                )]]
                and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
            </Select>
            <!-- Member Added or Removed from an AD Domain Local, Universal or  Global Security Group -->
            <Select Path="Security">
                EventID=4727 or <!--A security-enabled global group was created.-->
                EventID=4728 or <!--A member was added to a security-enabled global group.-->
                EventID=4729 or <!--A member was removed from a security-enabled global group.-->
                EventID=4731 or <!--A security-enabled local group was created.-->
                EventID=4732 or <!--A member was added to a security-enabled local group.-->
                EventID=4733 or <!--A member was removed from a security-enabled local group.-->
                EventID=4754 or <!--A security-enabled universal group was created.-->
                EventID=4756 or <!--A Member added to security-enabled universal group.-->
                EventID=4757 and <!--A member was removed from a security-enabled universal group.--> 
                (*[EventData[Data[@Name="TargetUserName"] = "Administrators"]]) or
                (*[EventData[Data[@Name="TargetUserName"] = "Domain Admins"]]) or
                (*[EventData[Data[@Name="TargetUserName"] = "Schema Admins"]]) or
                (*[EventData[Data[@Name="TargetUserName"] = "Enterprise Admins"]]) or
                (*[EventData[Data[@Name="TargetUserName"] =  "Print Operators"]]) or
                (*[EventData[Data[@Name="TargetUserName"] = "Server Operators"]]) or
                (*[EventData[Data[@Name="TargetUserName"] = "Backup Operators"]])               
                and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
            </Select>
            <Suppress Path="Security">
			    *[System[(
                EventID='4798' or
                EventID='4799'
                )]]			
	        </Suppress>
        </Query>
        <Query Id="3" Path="Security">
             <Select Path="Security">
                EventID=4719  <!--System audit policy was changed.-->
                and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
             </Select>
             <Suppress Path="Security">
                *[EventData[Data[@Name='SubjectDomainName'] and (Data='CORP')]]
            </Suppress>
        </Query>
         <Query Id="4" Path="Security">
             <Select Path="Security">
                EventID=4663 <!--An attempt was made to access an object.-->
                and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
             </Select>
            <Suppress Path="Security">
                *[EventData[Data[@Name='AccessMask'] and (
                Data='0x1' or <!--ReadData-->
                Data='0x80' or <!--ReadAttributes-->
                Data='0x20' <!--Traverse-->
                )]] 
                or *[EventData[Data[@Name='SubjectUserName'] and (
                Data='monitoringService'
                )]]
            </Suppress>
        </Query>
        <Query Id="5" Path="Security">
            <Select Path="Security">
                EventID=4625 <!--An account failed to log on.-->
                and *[System[TimeCreated[@SystemTime&gt;='$(date $cTimestamp.ToUniversalTime() -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']]]
            </Select>
            <Suppress Path="Security">
                *[EventData[Data[@Name='TargetUserName'] and (
                Data='Guest'
                )]]
            </Suppress>
        </Query>
    </QueryList>
"@
    get-winevent -FilterXml $filterxml | select 'RecordId',@{N='Log Type';E={$_.LogName}},@{N='Level';E={$_.LevelDisplayName}},@{N='Date and Time';E={$_.TimeCreated}},
        @{N='Source';E={$_.ProviderName}},@{N='Event ID';E={$_.ID}},'Message',@{N='EventXml';E={$_.ToXml()}}

}# End of Script Block

#splatting invoke arguments
$InvokeArgs = @{
    ComputerName = $(Get-LDAPServers | Where {$_ -match 'corp.example.com'})
    ScriptBlock = $SB
    Credential = $CorpCredential
    ArgumentList = $cTimestamp
    }

Invoke-Command @InvokeArgs -AsJob | Out-Null

$InvokeArgs = @{
    ComputerName = $(Get-LDAPServers | Where {$_ -match 'ad.example.com'})
    ScriptBlock = $SB
    Credential = $AdCredential
    ArgumentList = $cTimestamp
    }

Invoke-Command @InvokeArgs -AsJob | Out-Null

$Data = Start-AsJobHandler

# Database variables
$sqlserver = "sqlbeat01.corp.example.com"
$database = "Notification"
$table = "securityEventLog"

$Select =  @{N='computerName';E={$_.PSComputerName}},'RecordId', @{N='LogType';E={$_.'Log Type'}},'Level', @{N='DateAndTime';E={$_.'Date and Time'}},'Source', @{N='EventID';E={$_.'Event ID'}},'Message',@{N='eventXML';E={$_.'EventXml'}} 

Set-SqlData -data $($Data.RespondingSystems | select $Select) -server $sqlserver -database $database -table $table


#write errors to SQL error table
# Database variables
$sqlserver = "sqlbeat01.corp.example.com"
$database = "Notification"
$table = "readWindowsEvents_error"

$Select =  @{N='DateAndTime';E={$_.'Date and Time'}},@{N='computerName';E={$_."Computer Name"}},@{N='error';E={$_.'Error'}}

Set-SqlData -data $($Data.NOT_RespondingSystems | select $Select) -server $sqlserver -database $database -table $table