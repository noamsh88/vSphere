###############################################################
# Script getting VMList and revert VMs to thier latest snpashot
###############################################################
$VMList = $args[0]
$CredFilePath = "D:\vCenter\Credentials.xml"
###############################################################

# Validate VMList variable value not null
if (!$VMList) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <VM Name/List> "
  Write-Host "e.g."
  Write-Host "Single Host:      .\$scriptName VM1"
  Write-Host "Multiple Hosts:   .\$scriptName VM1,VM2,VM3"
  exit 1
}

# Load VMware Core Module
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

# Revert each VM in VMList to its latest snapshot
foreach($vm in $VMList.split(',')){
    # Validate VM exist on vsphere
    $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
    if (!$Exists){
      Write-Host "$vm VM NOT FOUND at $vCenterName vCenter, exiting.."
      exit 1
    }

    # Get latest snapshot of VM
    $LatestSnapshotName = Get-Snapshot -VM $vm | Sort-Object -Property Created -Descending | Select -First 1

    # Validate no snapshot found for this VM
    if (!$LatestSnapshotName)
    {
        Write-Output "No Snapshots found for $vm VM, skipping.."
        Continue;
    }

    # Revert VM to its latest snapshot
    Set-VM -VM $vm -SnapShot $LatestSnapshotName -Confirm:$false
}
