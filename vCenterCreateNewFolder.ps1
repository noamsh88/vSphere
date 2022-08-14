############################################################################################
#Script login to vCenter and create directory under home directory specified ($HomeDirName)#
############################################################################################
$DirName = $args[0]
##############################################################################################
$CredFilePath = "D:\vCenter\Credentials.xml"
$HomeDirName = "Dev-VMs" # Specify Home directory for new directory that going to be created
##############################################################################################

# Validate if argument entered is not null
if (!$DirName) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <Directory Name>"
  Write-Host "e.g."
  Write-Host "pwsh $scriptName Env1"
  exit 1
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

# Create directory name ($DirName) if not exist on vCenter
$DirExist = Get-Folder -Type VM | Where-Object {$_.name -eq $DirName}
if ($DirExist -eq $null) {
    New-Folder -Name "$DirName" -Location (Get-Folder $HomeDirName)
}
else {
    Write-Host "$DirName Folder exists already" -BackgroundColor DarkGreen
}
