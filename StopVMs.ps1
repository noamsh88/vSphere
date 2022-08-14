##############################################################################################
#Script login to vCenter and will stop single or multiple VMs according to argumentet entered#
##############################################################################################
$VMList = $args[0]
$CredFilePath = "D:\vCenter\Credentials.xml"
##############################################################################################

# Validate if argument entered is not null
if (!$VMList) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <VM Name/List>"
  Write-Host "e.g."
  Write-Host "Single Host:      .\$scriptName VM1"
  Write-Host "Multiple Hosts:   .\$scriptName VM1,VM2,VM3"
  exit 1
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials


foreach($vm in $VMList.split(','))
{
   Write-Host "Checking $vm VM"
   # Validate if VM exist on vCenter
   $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
   If ($Exists){
    Write-Host "Stopping VM: $vm"
   }
   else {
    Write-Host "$vm VM not found at $vCenterName vCenter, exiting.."
    exit 1
    }

   $VMPowerState = Get-VM -Name $vm | Select PowerState
   Write-Host "$VMPowerState"

   # Stopping VM if it powered on
   if ($VMPowerState -like "*PoweredOff*"){
   Write-Host "$vm VM is already Powered OFF, skipping.."
   }
   else
   {
   Stop-VM -VM $vm -Confirm:$false
   }
