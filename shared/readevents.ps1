param($cServerName, $cUserName, $cPassword, $cTimestamp)

$cQuery = "select * from win32_ntlogevent where (((logfile = 'system' or logfile = 'application') and (type <> 'Information' or SourceName = 'Kernel-General' or SourceName = 'EventLog' or SourceName = 'USER32' or SourceName = 'Microsoft-Windows-Kernel-General' or EventIdentifier = '1314' or SourceName = 'Microsoft-Windows-WAS')) and EventIdentifier <> '36871' and EventIdentifier <> '36887' and EventIdentifier <> '36874' and EventIdentifier <> '36888' and EventIdentifier <> '4663' and EventIdentifier <> '4656' and EventIdentifier <> '4658' and EventIdentifier <> '4690' and EventIdentifier <> '4624') and TimeWritten>'" + $cTimestamp+ "'"

if (!$cUserName) {
	$colItems = get-wmiobject -Computer $cServerName -query $cQuery
} else {
	$encryptedPassword = ConvertTo-SecureString $cPassword -AsPlainText -Force
	$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $cUserName,$encryptedPassword 
	$colItems = get-wmiobject -Computer $cServerName -Credential $cred -query $cQuery
}

foreach ($objItem in $colItems) {
      write-host "Category: " $objItem.Category
      write-host "Category String: " $objItem.CategoryString
      write-host "Data: " $objItem.Data
      write-host "Event Code: " $objItem.EventCode
      write-host "Event Identifier: " $objItem.EventIdentifier
      write-host "Event Type: " $objItem.EventType
      write-host "Insertion Strings: " $objItem.InsertionStrings
      write-host "Logfile: " $objItem.Logfile
      write-host "Message: " $objItem.Message
      write-host "Record Number: " $objItem.RecordNumber
      write-host "Source Name: " $objItem.SourceName
      write-host "Time Generated: " $objItem.TimeGenerated
      write-host "Time Written: " $objItem.TimeWritten
      write-host "Type: " $objItem.Type
      write-host "User: " $objItem.User
      write-host "*/*/*"
}
