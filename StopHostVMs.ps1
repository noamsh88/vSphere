#############################################################################
#Script login to vCenter and will stop all VMs related to host name entered #
#############################################################################
$HostName = $args[0]
$CredFilePath = "D:\vCenter\Credentials.xml"
#############################################################################

# Validate if argument entered is not null
if (!$HostName) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <Host/ESXi name>"
  Write-Host "e.g."
  Write-Host "pwsh $scriptName esxi-name-01"
  exit 1
}

# Load VMware Core Module
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

# Validate Host name exist at vsphere
$HostExists = Get-VMHost $HostName -ErrorAction SilentlyContinue
if (!$HostExists) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "$HostName Host NOT FOUND at $vCenterName vsphere, exiting.."
  exit 1
}

# Get Host VM List
$VMList = Get-VMHost $HostName | Get-VM | Select-Object Name

# Stop all Host VMs
foreach($vm in $VMList)
{
   Write-Host "Checking $vm VM"
   # Validate if VM exist on vCenter
   $Exists = get-vm -name $vm -ErrorAction SilentlyContinue
   If ($Exists){
    Write-Host "Stopping VM: $vm"
   }
   else {
    Write-Host "$vm VM not found at $vCenterName vCenter, skipping.."
    Continue
    }

   # Get VM state (powered on/off)
   $VMPowerState = Get-VM -Name $vm | Select PowerState
   Write-Host "$VMPowerState"

   # Stopping VM if it powered on
   if ($VMPowerState -like "*PoweredOff*"){
   Write-Host "VM --> ", $vm, " is already Powered OFF, skipping.."
   }
   else
   {
     Stop-VM -VM $vm -Confirm:$false
   }

}
