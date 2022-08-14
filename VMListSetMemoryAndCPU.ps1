#################################################################################################################################################
#Script login to vCenter and will set given CPU and Memory to VMList entered
#################################################################################################################################################
# VMs List must to be Powered Off (script to be executed as part of pipeline: Power OFF VMs -> set new cpu and memory to all VMs -> Power ON VMs)
#Reference: https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/Script-to-set-the-CPU-and-Memory-for-VMs/td-p/1348495
#################################################################################################################################################
$VMList = $args[0]
$cpu = $args[1]
$memory = $args[2]
$CredFilePath = "D:\vCenter\Credentials.xml"
#################################################################################################################################################

#Validate if argument entered is not null
if (!$VMList -Or !$cpu -Or !$memory) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "./$scriptName <VM Name/List> <CPU in GB> <Memory in GB> "
  Write-Host "e.g."
  Write-Host "Single Host:      ./$scriptName VM1 8 24"
  Write-Host "Multiple Hosts:   ./$scriptName VM1,VM2,VM3 8 16"
  exit 1
}

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
 # Validate if VM name exist on vCenter
 $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
 If (!$Exists){
    Write-Host "$vm VM NOT FOUND at $vCenterName vCenter, exiting.."
    exit 1
 }

 # Validate if VM is powered on
 $VMPowerState = Get-VM -Name $vm | Select PowerState
 Write-Host "$VMPowerState"
 if ($VMPowerState -like "*PoweredOn*"){
   Write-Host "$vm VM is powered ON, please stop it first and then re-run, exiting.."
   exit 1
 }

 # Set CPU and Memory to each VM on VMList
 try{
    Set-VM -VM $vm -NumCpu $cpu -MemoryGB $memory -Confirm:$false
    }
 catch{
    Write-Host "Error: $($_.Exception.Message)"
    }

 }
