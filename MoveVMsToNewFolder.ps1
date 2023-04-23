#########################################################################################################################################
#Script login to vCenter and create directory under home directory specified ($HomeDirName) and move all VMList to specified folder name#
#########################################################################################################################################
$VMList = $args[0]
$DirName = $args[1]
$CredFilePath = "D:\vCenter\Credentials.xml"
$HomeDirName = "Dev-Envs" # Specify Home directory for new directory that going to be created
#########################################################################################################################################

# Validate if argument entered is not null
if (!$DirName -Or !$VMList) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <VM List> <Directory Name>"
  Write-Host "e.g."
  Write-Host "./$scriptName VM1,VM2,VM3 VM-TST-1"
  exit 1
}

# Load VMWare module
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
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


# Move VMs to new directory
foreach($vm in $VMList.split(','))
{
   Write-Host "Validating if $vm VM exist on vCenter"
   $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
   If ($Exists){
    Write-Host "Moving VM: $vm to $DirName directory"
    New-Folder -Name "$DirName" -Location (Get-Folder -Name $HomeDirName | Select -first 1)
   }
   else {
    Write-Host "$vm VM NOT FOUND at $vCenterName vCenter, exiting.."
    exit 1
    }
}
