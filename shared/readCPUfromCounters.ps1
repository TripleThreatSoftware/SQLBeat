param($cServerName, $cWMIUserName, $cWMIPassword, $cSQLUserName, $cSQLPassword)

#Get Functions
#if ($psISE){
#    (Get-ChildItem (Join-Path (Split-Path $psISE.CurrentFile.FullPath) Functions) -Filter *.ps1) | % {. $_.FullName}
#}else{
#    (Get-ChildItem (Join-Path $PSScriptRoot Functions) -Filter *.ps1) | % {. $_.FullName}
#}

function ConvertTo-DataTable
{
    <#
    .Synopsis
        Creates a DataTable from an object
    .Description
        Creates a DataTable from an object, containing all properties (except built-in properties from a database)
    .Example
        Get-ChildItem| Select Name, LastWriteTime | ConvertTo-DataTable
    .Link
        Select-DataTable
    .Link
        Import-DataTable
    .Link
        Export-Datatable
    #> 
    [OutputType([Data.DataTable])]
    param(
    # The input objects
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)]
    [PSObject[]]
    $InputObject
    ) 
 
    begin { 
        
        $outputDataTable = new-object Data.datatable   
          
        $knownColumns = @{}
        
        
    } 

    process {         
               
        foreach ($In in $InputObject) { 
            $DataRow = $outputDataTable.NewRow()   
            $isDataRow = $in.psobject.TypeNames -like "*.DataRow*" -as [bool]

            $simpleTypes = ('System.Boolean', 'System.Byte[]', 'System.Byte', 'System.Char', 'System.Datetime', 'System.Decimal', 'System.Double', 'System.Guid', 'System.Int16', 'System.Int32', 'System.Int64', 'System.Single', 'System.UInt16', 'System.UInt32', 'System.UInt64')

            $SimpletypeLookup = @{}
            foreach ($s in $simpleTypes) {
                $SimpletypeLookup[$s] = $s
            }            
            
            
            foreach($property in $In.PsObject.properties) {   
                if ($isDataRow -and 
                    'RowError', 'RowState', 'Table', 'ItemArray', 'HasErrors' -contains $property.Name) {
                    continue     
                }
                $propName = $property.Name
                $propValue = $property.Value
                $IsSimpleType = $SimpletypeLookup.ContainsKey($property.TypeNameOfValue)

                if (-not $outputDataTable.Columns.Contains($propName)) {   
                    $outputDataTable.Columns.Add((
                        New-Object Data.DataColumn -Property @{
                            ColumnName = $propName
                            DataType = if ($issimpleType) {
                                $property.TypeNameOfValue
                            } else {
                                'System.Object'
                            }
                        }
                    ))
                }                   
                
                $DataRow.Item($propName) = if ($isSimpleType -and $propValue) {
                    $propValue
                } elseif ($propValue) {
                    [PSObject]$propValue
                } else {
                    [DBNull]::Value
                }
                
            }   
            $outputDataTable.Rows.Add($DataRow)   
        } 
        
    }  
      
    end 
    { 
        ,$outputDataTable

    } 
 
}

[Byte[]] $key = (1..16)
	$encryptedPassword = ConvertTo-SecureString $cWMIPassword -AsPlainText -Force
	$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $cWMIUserName,$encryptedPassword 


$SB = {  
    (Get-Counter '\Processor Information(*)\% Processor Utility' -SampleInterval 1 -MaxSamples 20).CounterSamples |
        Select InstanceName, CookedValue |
        Group-Object -Property InstanceName | % {
            $Stats = $_.Group | Measure-Object -Property CookedValue -Average -Maximum
            [PSCustomObject]@{
                'Timestamp' = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.ms")
                'Name' = $_.name
                'Average' = [math]::round(($Stats).Average,2)
                'Maximum' = [math]::round(($Stats).Maximum,2)
            }
        }
}
#Pre clean up just in case
$error.clear() 
Get-Job | Remove-Job




# $cUserName = "CORP\monitoringservice"
# $AdUserId = "ad.example.com\SA_Monitoring"
# $EncryptedPassword = 'REDACTED'

# $CorpCredential = Test-Credential $(New-Object System.Management.Automation.PSCredential -ArgumentList ($cUserName, ($EncryptedPassword | ConvertTo-SecureString -Key $key)))
# $AdCredential = Test-Credential $(New-Object System.Management.Automation.PSCredential -ArgumentList ($AdUserId, ($EncryptedPassword | ConvertTo-SecureString -Key $key)))


#splatting invoke arguments
$InvokeArgs = @{
    ComputerName = $cServerName
    ScriptBlock = $SB
    Credential = $cred
    ErrorAction = "SilentlyContinue"
    }

Invoke-Command @InvokeArgs -AsJob  | Out-Null

#Progress of job activity.
while((Get-Job).HasMoreData -and (Get-Job).State -eq "Running"){
    foreach ($job in ((get-job).childjobs)){        
        Write-Progress -Activity 'Collecting CPU utilization...' -CurrentOperation $job.Location -PercentComplete ((((get-job).childjobs |
        Where {($_.State -eq "Completed") -or ($_.State -eq "Failed")}).Count  / ((get-job).childjobs).Count) * 100)               	
        Start-Sleep -s 1              
    }   
}
if ((Get-Job).State -like "Running") { Get-Job | Stop-Job }
Write-Progress -Activity 'Collecting CPU utilization...' -Status "Completed." -Completed

#Get job data for long term use
$NOT_RespondingSystems = @()
$RespondingSystems = foreach ($job in (Get-Job).ChildJobs){
    If ($Job.JobStateInfo.State -eq 'Failed'){
        $NOT_RespondingSystems += [PSCustomObject]@{
            'Computer Name' = $Job.location
            'Error' = $Job.JobStateInfo.Reason.Message
        }
    }elseif($Job.JobStateInfo.State -eq 'Completed'){
         $Job.output

    }  
} 
#Clean up Jobs    
Get-Job | Remove-Job

# Database variables
$sqlserver = "127.0.0.1"
$database = "Notification"
$table = "cpuCounter_raw"

# 50k worked fastest and kept memory usage to a minimum
$batchsize = 50000

# Build the sqlbulkcopy connection, and set the timeout to infinite
$connectionstring = "Data Source=$sqlserver;User ID=$cSQLUserName;Password=$cSQLPassword;Initial Catalog=$database;"
$bulkcopy = New-Object Data.SqlClient.SqlBulkCopy($connectionstring, [System.Data.SqlClient.SqlBulkCopyOptions]::TableLock)
$bulkcopy.DestinationTableName = $table
$bulkcopy.bulkcopyTimeout = 0
$bulkcopy.batchsize = $batchsize

$Select = @{N=’Computer Name’; E={$_.PSComputerName}}, 'Timestamp', 'Name', 'Average', 'Maximum' 

$datatable = $RespondingSystems | select $Select | ConvertTo-DataTable

# Add in all the remaining rows since the last clear
if($datatable.Rows.Count -gt 0) {
	$bulkcopy.WriteToServer($datatable)
	$datatable.Clear()
}

# Clean Up
$bulkcopy.Close(); $bulkcopy.Dispose()
$datatable.Dispose()

#write errors to SQL error table
# Database variables
$sqlserver = "127.0.0.1"
$database = "Notification"
$table = "cpuCounter_error"

# 50k worked fastest and kept memory usage to a minimum
$batchsize = 50000

# Build the sqlbulkcopy connection, and set the timeout to infinite
$connectionstring = "Data Source=$sqlserver;User ID=$cSQLUserName;Password=$cSQLPassword;Initial Catalog=$database;"
$bulkcopy = New-Object Data.SqlClient.SqlBulkCopy($connectionstring, [System.Data.SqlClient.SqlBulkCopyOptions]::TableLock)
$bulkcopy.DestinationTableName = $table
$bulkcopy.bulkcopyTimeout = 0
$bulkcopy.batchsize = $batchsize

$Select =  @{N='computerName';E={$_."Computer Name"}},'Error'

$datatable = $NOT_RespondingSystems | select $Select | ConvertTo-DataTable

# Add in all the remaining rows since the last clear
if($datatable.Rows.Count -gt 0) {
	$bulkcopy.WriteToServer($datatable)
	$datatable.Clear()
}

# Clean Up
$bulkcopy.Close(); $bulkcopy.Dispose()
$datatable.Dispose()