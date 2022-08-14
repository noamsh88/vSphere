################################################################################################
#Script login to vCenter and will remove single or multiple VMs according to argumentet entered#
################################################################################################
$VMList = $args[0]
$CredFilePath = "D:\vCenter\Credentials.xml"
################################################################################################

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
   # Validate if VM exist on vCenter
   $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
   If ($Exists){
    Write-Host "Removing VM: $vm"
   }
   else {
    Write-Host "$vm VM not found at $vCenterName vCenter, exiting.."
    exit 1
    }

    # Check if VM is powered on, if not, VMPoweredOn variable value will remain null
    $VMPoweredOn = Get-VM -Name $vm | Select PowerState | Select-String 'PoweredOn'

    # if VM is powered off, remove it, else, exit with error
    if (!$VMPoweredOn) {
     Remove-VM -VM $vm -DeletePermanently -Confirm:$false
    }
    else {
     Write-Host "$vm VM is Powered ON, please stop it first before removing it, exiting..."
     exit 1
    }
}
