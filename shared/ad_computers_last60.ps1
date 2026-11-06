param($cServerName, $cUserName, $cPassword)

$encryptedPassword = ConvertTo-SecureString $cPassword -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $cUserName,$encryptedPassword 
Get-ADComputer -Server $cServerName -Credential $cred -Filter * -Properties *