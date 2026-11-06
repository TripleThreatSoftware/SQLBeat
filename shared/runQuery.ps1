param($cServerName, $cUserName, $cPassword, $cQuery)

if (!$cUserName) {
	$colItems = get-wmiobject -Computer $cServerName -query $cQuery
} else {
	$encryptedPassword = ConvertTo-SecureString $cPassword -AsPlainText -Force
	$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $cUserName,$encryptedPassword 
	$colItems = get-wmiobject -Computer $cServerName -Credential $cred -query $cQuery
}

foreach ($objItem in $colItems) {
	write-host $objItem.Name
	write-host "**********"
	foreach ($objItemProperties in $objItem.PsObject.Properties) {
		write-host $objItemProperties.Name
		write-host $objItemProperties.Value
		write-host "*/*/*"
	}      
}
