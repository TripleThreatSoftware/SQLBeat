param($cServerName, $cUserName, $cPassword, $cObjectName)

$cQuery = "select * from " + $cObjectName

if (!$cUserName) {
	$colItems = get-wmiobject -Computer $cServerName -query $cQuery
} else {
	$encryptedPassword = ConvertTo-SecureString $cPassword -AsPlainText -Force
	$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $cUserName,$encryptedPassword 
	$colItems = get-wmiobject -Computer $cServerName -Credential $cred -query $cQuery
}

foreach ($objItem in $colItems) {
	foreach ($objProperty in $objItem.properties) {
	      write-host "||" $objProperty.Name "~~" $objProperty.Value
	}
      write-host "*/*/*"
}
