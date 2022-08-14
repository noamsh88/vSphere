##############################################################################################################
#Script login to vCenter and will clean VM snapshots for single or multiple VMs according to argument entered#
##############################################################################################################
$VMList = $args[0]
##############################################################################################

# Validate if argument entered is not null
if (!$VMList) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <VM Name/List> <SnapshotName>"
  Write-Host "e.g."
  Write-Host "Single Host:      pwsh $scriptName VM1"
  Write-Host "Multiple Hosts:   pwsh $scriptName VM1,VM2,VM3"
  exit 1
}

Write-Host "VMList = $VMList"

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

foreach($vm in $VMList.split(','))
{
   # Validate if VM exist on vCenter
   $Exists = get-vm -name $vm -ErrorAction SilentlyContinue
   If (!$Exists){
    Write-Host "$vm VM not found at $vCenterName vCenter, skipping.."
    Continue
    }

    Write-Host "$vm VM Snapshots to be deleted:"
    Get-Snapshot -VM $vm | Select Name, Created

    try
    {
       Get-Snapshot -VM $vm | Remove-Snapshot -Confirm:$false
    }
    catch
    {
        Write-Host "Fail to Clean all VM Snapshots - VM: $vm"
        Write-Host "Error: $($_.Exception.Message)"
    }
}
