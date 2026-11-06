param($cServerName, $cUserName, $cPassword, $cTimestamp)

$cQuery = "select * from win32_ntlogevent where logfile = 'security' and EventIdentifier = '4663' and not message like '%ReadData%' and not message like '%ReadAttributes%' and not message like '%Traverse%' and not message like '%ProgramData%Symantec%' and TimeWritten > '" + $cTimestamp+ "'"

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
