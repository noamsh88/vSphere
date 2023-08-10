##################################################################################################
# Script getting vm name, hard disk name and size in gb and extend VM hard disk with size entered
##################################################################################################
$vmName = $args[0]
$diskName= $args[1]   # Disk name, ususally will be Hard Disk 1/2/..
[int]$sizeGB = $args[2]    # Size to be added to hard disk of VM
$CredFilePath = "D:\vCenter\Credentials.xml"
##################################################################################################

# Validate vmName variable value not null
if (!$vmName -Or !$diskName -Or !$sizeGB) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <VM Name/List> "
  Write-Host "e.g."
  Write-Host ".\$scriptName VM1 \'Hard disk 2\' 50"
  exit 1
}

# Load VMware Core Module
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -WebOperationTimeoutSeconds 3600 -Confirm:$false

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

# Validate VM exist on vsphere
$Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
if (!$Exists){
  Write-Host "$vm VM not found at $vCenterName vCenter, exiting.."
  exit 1
 }

# Get the hard disk information for the VM
$hardDisk = Get-HardDisk -VM $vmName -Name $diskName

# Get current Hard disk in GB
[int]$harDiskSizeGB = [math]::Round($hardDisk.CapacityGB, 2)
Write-Host "Current Hard Disk $($hardDisk.Name) size: $diskSizeGB GB"

# Set Target Hard Disk Size
[int]$targetHarDiskSizeGB = $harDiskSizeGB + $sizeGB
Write-Host "Target Size in gb: $targetHarDiskSizeGB"

# Extend Hard Disk size of VM in vsphere
Set-HardDisk -HardDisk $hardDisk -CapacityGB $targetHarDiskSizeGB
