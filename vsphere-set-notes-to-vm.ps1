# Script login to vSphere and will set the given notes to given VM name
$vm_name = $args[0]
$notes = $args[1]
$CredFilePath = "D:\vCenter\Credentials.xml"

# Validate script arguments entered
if (!$vm_name -Or !$notes) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "./$scriptName <VM Name> <Notes to be set to VM> "
  Write-Host "e.g."
  Write-Host "./$scriptName VM1 TestingVM"
  exit 1
}

# Load VMware Core Module
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

# Create Connection to vSphere
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

# Get the virtual machine object
$vm = Get-VM -Name $vm_name

# Set notes to VM
Set-VM -vm $vm -Description $notes -Confirm:$false
