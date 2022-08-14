##############################################################################################
#Script login to vCenter and validate if given directory name exist or not
##############################################################################################
$DirName = $args[0]
$CredFilePath = "D:\vCenter\Credentials.xml"
##############################################################################################

#Validate if argument entered is not null
if (!$DirName) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <Directory Name>"
  Write-Host "e.g."
  Write-Host "pwsh $scriptName NC30"
  exit 1
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

$DirExist = Get-Folder -Type VM | Where-Object {$_.name -eq $DirName}

if ($DirExist -eq $null) {
    Write-Host "$foldername Folder doesn't exist" -BackgroundColor Red
}
else {
    Write-Host "$DirName Folder exists" -BackgroundColor DarkGreen
}
