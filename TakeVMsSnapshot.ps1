##############################################################################################################
#Script login to vCenter and will take VM snapshot for single or multiple VMs according to argumentet entered#
##############################################################################################################
$VMList = $args[0]
$SnapshotName = $args[1]
$CredFilePath = "D:\vCenter\Credentials.xml"
##############################################################################################################

# Validate if argument entered is not null
if (!$VMList -Or !$SnapshotName) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <VM Name/List> <SnapshotName>"
  Write-Host "e.g."
  Write-Host "Single Host:      ./$scriptName VM1 B4_Deploy"
  Write-Host "Multiple Hosts:   ./$scriptName VM1,VM2,VM3 B4_Deploy"
  exit 1
}

write-host "SnapshotName = $SnapshotName"
# Get timestamp to be added at end of snapshot name
$date = get-date -Format "yyyy_MM_dd_hh_mm_ss_tt"

$SnapshotName = $SnapshotName+'_'+$date

write-host "VMList = $VMList"
write-host "SnapshotName = $SnapshotName"

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
    Write-Host "$vm VM not found at $vCenterName vCenter, exiting.."
    exit 1
    }

    try
    {
       Write-Host "Creating Snapshot for VM: $vm, Snapshot: $SnapshotName"
       New-Snapshot -VM $vm -Name $SnapshotName -Memory:$false
    }
    catch
    {
        Write-Host "Fail to Create New Snapshot - VM: $vm, Snapshot: $SnapshotName"
        Write-Host "Error: $($_.Exception.Message)"
        Write-Host "##vso[task.logissue type=warning;]Fail to Create New Snapshot - VM: $vm, Snapshot: $SnapshotName!"
        Write-Host "##vso[task.complete result=SucceededWithIssues;]"
    }
}
